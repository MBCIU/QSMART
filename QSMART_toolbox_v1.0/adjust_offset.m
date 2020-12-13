function combined_chi_adjusted_offset=adjust_offset(removed_voxs,lfs_sdf,chi_iLSQR_1,chi_iLSQR_2,params)

lfs_sdf=lfs_sdf/params.ppm; % Scaling to perform offset adjustment

removed_voxs(removed_voxs<0)=0;
nii = make_nii(removed_voxs, params.iminfo.resolution);
save_nii(nii,'removed_voxels.nii');
chi_iLSQR_1(removed_voxs==0) = 0;
combined_chi = chi_iLSQR_1+chi_iLSQR_2 ;
nii = make_nii(combined_chi, params.iminfo.resolution);
save_nii(nii,'combined_chi.nii');
% adjust the offset 
Nx = size(chi_iLSQR_1,1);
Ny = size(chi_iLSQR_1,2);
Nz = size(chi_iLSQR_1,3);
FOV = params.iminfo.resolution.*[Nx,Ny,Nz];
FOVx = FOV(1);
FOVy = FOV(2);
FOVz = FOV(3);

x = -Nx/2:Nx/2-1;
y = -Ny/2:Ny/2-1;
z = -Nz/2:Nz/2-1;
[kx,ky,kz] = ndgrid(x/FOVx,y/FOVy,z/FOVz);
D = 1/3 - (kx.*params.iminfo.z_prjs(1)+ky.*params.iminfo.z_prjs(2)+kz.*params.iminfo.z_prjs(3)).^2./(kx.^2 + ky.^2 + kz.^2);
D(floor(Nx/2+1),floor(Ny/2+1),floor(Nz/2+1)) = 0;
D = fftshift(D);


x1 = ifftn(D.*fftn(removed_voxs));
x2 = (lfs_sdf - ifftn(D.*fftn(combined_chi)));
x1 = x1(:);
x2 = x2(:);
o = real(x1'*x2/(x1'*x1));

combined_chi_adjusted_offset = combined_chi + o*removed_voxs;

nii = make_nii(combined_chi_adjusted_offset,params.iminfo.resolution);
save_nii(nii,'QSMART_adjusted_offset.nii');

try; reorient_nii('QSMART_adjusted_offset.nii');end

