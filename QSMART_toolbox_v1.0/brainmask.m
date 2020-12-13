function mask=brainmask(mag_all,params)

vox = params.iminfo.resolution;

disp('---generating initial brain mask---');

mag1_sos = sqrt(sum(mag_all(:,:,:,1,:).^2,5));
nii = make_nii(mag1_sos,vox); %%makes NIfTI image
save_nii(nii,'mag1_sos.nii');
%%bias field correction
unix('module load ants/1.9.v4; N4BiasFieldCorrection -i mag1_sos.nii -o mag1_sos_n4.nii');
%%mask
%(1) brain mask
unix('module load fsl/5.0.9; bet2 mag1_sos_n4.nii BET -f 0.2 -m');
% set a lower threshold for postmortem
% unix('bet2 mag1_sos.nii BET -f 0.1 -m');
unix('gunzip -f BET.nii.gz');
unix('gunzip -f BET_mask.nii.gz');
nii = load_nii('BET_mask.nii');
mask = double(nii.img); %%0 and 1 s
nii = load_nii('BET.nii');
BET_map=nii.img;

if params.adaptive_threshold
     params.mag_threshold = prctile(BET_map(BET_map~=0),params.mag_thresh_percentile);
     fprintf('Setting adaptive magnitue threshold at %2.2f \n',params.mag_threshold);
end

mask(BET_map<params.mag_threshold)=0;
mask = bwmorph3(mask,'majority');
% close the mask
SE = strel('sphere',params.sph_radius1);
mask = imclose(mask,SE);

mask=double(mask);
nii = make_nii(mask,vox);
save_nii(nii,'BET_mask.nii');

