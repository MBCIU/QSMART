function Clean=sdf_curvature(tfs,mask,vasc_only,sigma1,sigma2,vox,lowerLim,curvConstant,stage)
disp('---spatially dependent filtering to remove background field---');
   
imsize=size(tfs);
x=zeros(imsize(1:3));
PhiK=zeros(imsize(1:3));
BckGnd=zeros(imsize(1:3));
sigma=sqrt(sigma1^2+sigma2^2);
n=-log(sigma)/log(0.5);

% Calculating initial proximity mask
prox1=imgaussfilt3(mask,[sigma1 2*sigma1 2*sigma1]).*mask;

% Calculating curvature-based edge proximity maps
prox=calculate_curvature(mask, prox1, lowerLim, curvConstant, sigma1,vox);
 
if stage==2
    % Calculating vasculature proximity 
    prox2=imgaussfilt3(vasc_only,sigma2).*mask;
    prox=prox.*prox2;
end

nii=make_nii(prox,vox);
save_nii(nii,'prox.nii');

alpha=sigma*round(prox.^n,2).*mask;
alpha(find((~vasc_only)&mask))=1;
nii=make_nii(alpha,vox);
save_nii(nii,'alpha.nii');

u=unique(alpha(:));
A=sort(u);
%m=min(A(A>0));

x=zeros(imsize(1:3));
for i=1:length(A)
x(find(alpha==A(i)))=i;
end

PhiK=zeros(imsize(1:3));
BckGnd=zeros(imsize(1:3));

tic
for i=1:length(A)
    if A(i)>0%avoid sigma=0
       % i
        num=imgaussfilt3((tfs.*mask),A(i),'filterSize',2*ceil(2*sigma)+1);
        denum=imgaussfilt3(mask,A(i),'filterSize',2*ceil(2*sigma)+1);
        PhiK=num./denum;
         else
        PhiK=tfs.*mask;
        end
        ind=find(x==i);
        BckGnd(ind)=PhiK(ind);
        clear PhiK
  
       
end
toc

%BckGnd(isnan(BckGnd))=0;
Clean=(tfs-BckGnd).*mask;
end