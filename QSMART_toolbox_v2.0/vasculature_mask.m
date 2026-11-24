function vasc_only= vasculature_mask(mag_corr,mask,params)

vox=params.iminfo.resolution;
mexEig3volume=params.mexEig3volume;
imsize=size(mag_corr);

disp('---generating vasculature mask---');
AvgEcho=mean(mag_corr,4);
%
nii = make_nii(AvgEcho,vox); %%makes NIfTI image
save_nii(nii,'AvgEcho.nii');
n4_correct('AvgEcho.nii', 'AvgEcho_n4.nii', params);
nii = load_nii('AvgEcho_n4.nii');
AvgEcho_n4=nii.img;

SE = strel('sphere',max(1,round(to_voxels(params.sph_radius_vasculature,params))));
test = imbothat(AvgEcho_n4,SE);
nii = make_nii(test,vox); %%makes NIfTI image
save_nii(nii,'test.nii');


% Frangi's c is in the magnitude's intensity units, and scanners scale magnitude very
% differently, so a fixed c labels a few percent of one scan's brain as vessel and over half of
% another's. With frangi_C_mode 'relative' (default), c is frangi_C_factor times the median
% N4-corrected echo-mean magnitude inside the brain mask; with 'absolute', c is frangi_C.
frangi_C = params.frangi_C;
if ~isfield(params, 'frangi_C_mode') || strcmp(params.frangi_C_mode, 'relative')
    brain_median = median(AvgEcho_n4(mask > 0));
    if ~(isfinite(brain_median) && brain_median > 0)
        error('QSMART:relativeC', 'A relative Frangi c needs a positive magnitude median inside the brain mask (got %g).', brain_median);
    end
    frangi_C = params.frangi_C_factor * brain_median;
    fprintf('Setting Frangi c at %.4g (%.3g x the median brain magnitude) \n', frangi_C, params.frangi_C_factor);
elseif ~strcmp(params.frangi_C_mode, 'absolute')
    error('QSMART:frangiCMode', 'frangi_C_mode must be ''relative'' or ''absolute'' (got ''%s'').', params.frangi_C_mode);
end

vasc_only=zeros(imsize(1:3));
system(sprintf('cp %s .',mexEig3volume))
mex eig3volume.c
options = struct('FrangiScaleRange', to_voxels(params.frangi_scaleRange,params), 'FrangiScaleRatio', to_voxels(params.frangi_scaleRatio,params), 'FrangiAlpha', 0.5,...
          'FrangiBeta', 0.5, 'FrangiC', frangi_C, 'verbose',true,'BlackWhite',false);
enhanced=FrangiFilter3D(test.*mask,options);
nii = make_nii(enhanced,vox); %%makes NIfTI image
save_nii(nii,'enhanced.nii');
%%Otsu's thresholding
T=graythresh(enhanced);
vasc_only(enhanced>T)=1;
%vasc_only=bwmorph3(vasc_only,'bridge');

vasc_only(find(~mask))=0;

% Vessels are a few percent of the brain. A much larger share means the vessel settings do not
% suit this data (often Otsu's threshold has collapsed to 0, see frangi_C_mode).
coverage = sum(vasc_only(:)) / sum(mask(:) > 0);
fprintf('Vessel mask covers %.1f%% of the brain mask \n', 100*coverage);
max_coverage = 0.2;
if isfield(params, 'vessel_coverage_warning') && ~isempty(params.vessel_coverage_warning)
    max_coverage = params.vessel_coverage_warning;
end
if coverage > max_coverage
    warning('QSMART:vesselCoverage', ['The vessel mask covers %.0f%% of the brain mask, which is implausibly ' ...
        'large: check the vessel settings (frangi_C_mode, frangi_C, frangi_scaleRange, ' ...
        'sph_radius_vasculature) and vasc_only.nii.'], 100*coverage);
end
vasc_only=double(~vasc_only);
nii = make_nii(vasc_only,vox); %%makes NIfTI image
save_nii(nii,'vasc_only.nii');
