function lfs = QSMART_SDF(tfs,mask,R_0,vasc_only,stage,params)

imsize=size(tfs);

%Inward indents
SE = strel('sphere',params.sdf_sp_radius);
fill = imclose(mask,SE);
indent=double(fill-mask);

if stage==1
    
    lfs_sdf_1=sdf_curvature(tfs,mask.*R_0,ones(imsize(1:3)),params.s1.sdf_sigma1,params.s1.sdf_sigma1,params.iminfo.resolution,...
        params.sdffilterLowerLim,params.sdffilterCurvConstant,stage);
    lfs=lfs_sdf_1*params.ppm; % converting to ppm
    nii = make_nii(lfs_sdf_1,params.iminfo.resolution); save_nii(nii,'lfs_sdf_1.nii');

elseif stage==2

    %clean the phase again
    lfs_sdf_2=sdf_curvature(tfs.*mask.*R_0,mask.*R_0,vasc_only,params.s2.sdf_sigma1,params.s2.sdf_sigma2,params.iminfo.resolution,...
        params.sdffilterLowerLim,params.sdffilterCurvConstant,stage);
    lfs=lfs_sdf_2*params.ppm; % converting to ppm
    nii = make_nii(lfs_sdf_2,params.iminfo.resolution); save_nii(nii,'lfs_sdf_2.nii');

end