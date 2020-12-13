function [tfs,R_0] = echofit(ph, mag, inter,params)
%ECHOFIT Magnitude-weighted least square regression of phase to echo time.
%   [TFS,RES, OFF, R_0] = echofit(PH,MAG,TE,INTER) fits the phases with TEs, weighted by
%   magnitudes and force inters to zeros
%
%   PH:    unwrapped phases from multiple echoes
%   MAG:   corresponding magnitudes to phases
%   TE:    echo times
%   THR:   Fit threshold for reliability map
%   INTER: intercept of linear fitting, zero or non-zero
%   TFS:   Total field shift after fitting
%   RES:   fitting residuals
%   OFF:   constant offset fitting intercept
%   R_0:   Reliability map

vox=params.iminfo.resolution;
TE=params.iminfo.echo_times;
% check ph and mag have same dimensions
if ~ size(ph)==size(mag)
    error('Input phase and magnitude must be in size');
end

if ~ exist('inter','var') || isempty(inter)
    inter = 0; % by default zero intercept
end

[np,nv,ns,ne] = size(ph);

ph = permute(ph,[4 1 2 3]);
mag = permute(mag,[4 1 2 3]);

ph = reshape(ph,ne,[]);
mag = reshape(mag,ne,[]);

if ~ inter
% if assume zero inter

	TE_rep = repmat(TE(:),[1 np*nv*ns]);

	tfs = sum(mag.*ph.*TE_rep,1)./(sum(mag.*TE_rep.*TE_rep)+eps);
	tfs = reshape(tfs,[np nv ns]);

	% caculate the fitting residual
	lfs_rep = permute(repmat(tfs(:),[1 ne]),[2 1]);
	res = reshape(sum((ph - lfs_rep.*TE_rep).*mag.*(ph - lfs_rep.*TE_rep),1)./sum(mag,1)*ne,[np nv ns]);% % normalize lfs ("/sum*ne")
	res(isnan(res)) = 0;
	res(isinf(res)) = 0;

else
		
	% non-zero inter
	x = [TE(:), ones(length(TE),1)];
	beta = zeros(2, np*nv*ns);
	res = zeros([np nv ns]);
	
	if exist('parpool')
		poolobj=parpool;
	else
		parpool open
	end

	parfor i = 1:np*nv*ns
		y = ph(:,i);
		w = mag(:,i);
		beta(:,i) = (x'*diag(w)*x)\(x'*diag(w)*y);
		res(i) = (y-x*beta(:,i))'*diag(w)*(y-x*beta(:,i))/sum(w)*ne;
	end
	
	if exist('parpool')
		delete(poolobj);
	else
		parpool close
	end

	beta(isnan(beta)) = 0;
	beta(isinf(beta)) = 0;
	res(isnan(res)) = 0;
	res(isinf(res)) = 0;

	tfs = reshape(beta(1,:),[np nv ns]);
	off = reshape(beta(2,:),[np nv ns]);
	res = reshape(res,[np nv ns]);

end

%%%
tfs = tfs/params.ppm; % unit ppm
nii = make_nii(tfs,vox); save_nii(nii,'tfs.nii');
nii = make_nii(res,vox); save_nii(nii,'fit_residual.nii');

% reliability map
fit_residual_blur = smooth3(res,'box',round(1./vox)*2+1); 
nii = make_nii(fit_residual_blur,vox); save_nii(nii,'fit_residual_blur.nii');
R_0 = ones(size(fit_residual_blur));

if params.adaptive_threshold
    params.fit_threshold=prctile(fit_residual_blur(fit_residual_blur~=0),params.fit_thresh_percentile);
    fprintf('Setting adaptive echo-fit threshold at %2.2f \n',params.fit_threshold);
end

R_0(fit_residual_blur >= params.fit_threshold) = 0;

