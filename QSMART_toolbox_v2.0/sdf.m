function Clean=sdf(tfs,mask,indent,vasc_only,sigma1,sigma2,vox,p_indent)
disp('---spatially dependent filtering to remove background field---');

   
imsize=size(tfs);
x=zeros(imsize(1:3));
PhiK=zeros(imsize(1:3));
BckGnd=zeros(imsize(1:3));
sigma=sqrt(sigma1^2+sigma2^2);
n=-log(sigma)/log(0.5);


%mask2=mask;
% mask2(find(EdgeMask(:,:,1:100)))=0.2;
%mask2(find(indent))=-1;
prox1=imgaussfilt3(mask,[sigma1 2*sigma1 2*sigma1]).*mask;
if sigma2
    prox2=imgaussfilt3(vasc_only,sigma2).*mask;
else
    prox2=ones(imsize);
end
prox3=imgaussfilt3((1-indent*p_indent.scale),p_indent.sigma).*mask;
prox=prox1.*prox2.*prox3;
 


%alpha(find((alpha<1)))=1;

% prox(find(EdgeMask))=0.5;
% one=imgaussfilt3(prox,3);
% two=imgaussfilt3(mask,3);
% prox=one./two.*mask;
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
