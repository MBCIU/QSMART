function vasc_only= vasculature_mask(mag_corr,mask,params)

vox=params.iminfo.resolution;
mexEig3volume=params.mexEig3volume;
imsize=size(mag_corr);

disp('---generating vasculature mask---');
AvgEcho=mean(mag_corr,4);
%
nii = make_nii(AvgEcho,vox); %%makes NIfTI image
save_nii(nii,'AvgEcho.nii');
unix('module load ants/1.9.v4; N4BiasFieldCorrection -i AvgEcho.nii -o AvgEcho_n4.nii');
nii = load_nii('AvgEcho_n4.nii');
AvgEcho_n4=nii.img;

SE = strel('sphere',params.sph_radius_vasculature);
test = imbothat(AvgEcho_n4,SE);
nii = make_nii(test,vox); %%makes NIfTI image
save_nii(nii,'test.nii');


vasc_only=zeros(imsize(1:3));
system(sprintf('cp %s .',mexEig3volume))
mex eig3volume.c
options = struct('FrangiScaleRange', params.frangi_scaleRange, 'FrangiScaleRatio', params.frangi_scaleRatio, 'FrangiAlpha', 0.5,...
          'FrangiBeta', 0.5, 'FrangiC', params.frangi_C, 'verbose',true,'BlackWhite',false);
enhanced=FrangiFilter3D(test.*mask,options);
nii = make_nii(enhanced,vox); %%makes NIfTI image
save_nii(nii,'enhanced.nii');
%%Otsu's thresholding
T=graythresh(enhanced);
vasc_only(enhanced>T)=1;
%vasc_only=bwmorph3(vasc_only,'bridge');

vasc_only(find(~mask))=0;
vasc_only=double(~vasc_only);
nii = make_nii(vasc_only,vox); %%makes NIfTI image
save_nii(nii,'vasc_only.nii');
