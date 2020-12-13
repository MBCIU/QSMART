function [ph_corr,mag_corr]=coil_comb(mag_all,ph_all,vox,TE,mask,polarity,coilcombmethod)

disp('---coil combination process---')

imsize = size(ph_all);

if strcmp(polarity,'unipolar')
% (1) if unipolar
[ph_corr,mag_corr] = geme_cmb(mag_all.*exp(1j*ph_all),vox,TE,mask,coilcombmethod);
elseif strcmp(polarity,'bipolar')
% (2) if bipolar
 ph_corr = zeros(imsize(1:4));
 mag_corr = zeros(imsize(1:4));
 [ph_corr(:,:,:,1:2:end),mag_corr(:,:,:,1:2:end)] = geme_cmb(mag_all(:,:,:,1:2:end,:).*exp(1j*ph_all(:,:,:,1:2:end,:)),vox,TE(1:2:end),mask);
 [ph_corr(:,:,:,2:2:end),mag_corr(:,:,:,2:2:end)] = geme_cmb(mag_all(:,:,:,2:2:end,:).*exp(1j*ph_all(:,:,:,2:2:end,:)),vox,TE(2:2:end),mask);

end

% save niftis after coil combination
mkdir('src');
for echo = 1:imsize(4)
    nii = make_nii(mag_corr(:,:,:,echo),vox);
    save_nii(nii,['src/mag_corr' num2str(echo) '.nii']);
    nii = make_nii(ph_corr(:,:,:,echo),vox);
    save_nii(nii,['src/ph_corr' num2str(echo) '.nii']);
end
