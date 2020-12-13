function [tfs,R_0] = filter_tfs(tfs,fit_residual,params)

vox=params.iminfo.resolution;
fit_thr=params.fit_threshold;

%%%
tfs = tfs/(params.gyromagnetic_ratio*params.MagneticFieldStrength)*1e6; % unit ppm
nii = make_nii(tfs,vox);
save_nii(nii,'tfs.nii');

nii = make_nii(fit_residual,vox);
save_nii(nii,'fit_residual.nii');

% extra filtering according to fitting residuals
% generate reliability map
fit_residual_blur = smooth3(fit_residual,'box',round(1./vox)*2+1); 
nii = make_nii(fit_residual_blur,vox);
save_nii(nii,'fit_residual_blur.nii');
R_0 = ones(size(fit_residual_blur));
R_0(fit_residual_blur >= fit_thr) = 0;


