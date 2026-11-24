function prox=calculate_curvature(mask, prox1, lowerLim, curvConstant, sigma,vox)
% This function calculates edge proximity maps using gaussian curvature* at
% the surface of the brain to reduce artifacts in QSMART output. The proximity maps define the filter-size for
% 3D spadially dependent filtering. 
% INPUTS: 
% mask: The mask of the brain (3D binary image)
% prox1: The initial proximity map without curvature adjustment
% lowerLim: The clamping value for the proximity map before edge-refinement
% curvConstatn: The scaling constant for the curvature values
% sigma: kernel size for the 3D Gaussian filter
% vox: Voxel size (mm^3)
% OUTPUTS:
% prox
% Author: Warda Syeda, Melbourne Neuropsychiatry Centre, The University of
% Melbourne, October 2020
% Email: wtsyeda@unimelb.edu.au
% *Reference: Alireza Dastan (2020). Gaussian and mean curvatures calculation on a triangulated 3d surface 
% (https://www.mathworks.com/matlabcentral/fileexchange/61136-gaussian-and-mean-curvatures-calculation-on-a-triangulated-3d-surface), 
% MATLAB Central File Exchange. Retrieved October 23, 2020.

curvMask=mask-imerode(mask,strel('sphere',1));

curvI = ones(size(mask));
maskInds=find(curvMask);
[x y z]=ind2sub(size(mask),maskInds);
tri=delaunay(x,y);
[GC,MC]=curvatures(x,y,z,tri);
scaledGC=GC./max(abs(GC(GC<0)))*curvConstant;
scaledGC(GC>0)=1;
curvI(maskInds)=scaledGC;

% Calculating and clamping curvature proximity mask
prox3=imgaussfilt3(curvI,[sigma 2*sigma 2*sigma]).*mask;
prox3(prox3<0.5 & prox3~=0)=0.5;

prox=prox1.*prox3;

% Calculating edge proximity
prox4=prox.*(mask-imerode(mask,strel('sphere',1))); 
prox4(prox4==0)=1;
prox4((imdilate(mask,strel('sphere',5))-mask)==1)=0; 
prox4=imgaussfilt3(prox4,[5 10 10]);

% Clamping proximity mask
prox(prox<lowerLim & prox~=0)=lowerLim;

% Edge refinement
prox=prox.*prox4;

% Saving curvature image
nii=make_nii(curvI,vox);
save_nii(nii,'curvature.nii');


