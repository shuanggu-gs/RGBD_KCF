function [gm, targetDepth] = init_distribution(color, depth, pos, target_sz, visualization)
%INITTAR Summary of this function goes here
%   Detailed explanation goes here
color=double(color);
depthIm=double(depth);
[H W Z]=size(color);

%background rgb distibution 
a = max(200, 4*(target_sz(2)));
bbE(1)=max(1,pos(2)-target_sz(2)/2-2*a);
bbE(2)=max(1,pos(1)-target_sz(1)/2-a);
bbE(3)=min(W,pos(2)+target_sz(2)/2+2*a);
bbE(4)=min(H,pos(1)+target_sz(1)/2+a);
back_color=double(color(bbE(2):bbE(4),bbE(1):bbE(3),:));
back_color(max(1,pos(1)-target_sz(1)/2):min(H,pos(1)+target_sz(1)/2),...
    max(1,pos(2)-target_sz(2)/2):min(W,pos(2)+target_sz(2)/2),:)=nan;
br=back_color(:,:,1);bg=back_color(:,:,2);bb=back_color(:,:,3);

% back_color = double(get_subwindow(color, pos, expand_sz));
% % back_rgb(max(1,bbIn(2)):min(H,bbIn(4)),max(1,bbIn(1)):min(W,bbIn(3)),:)=nan;
% back_color(floor(target_sz(1)*padding/2):floor(target_sz(1)*padding/2)+target_sz(1),...
%     floor(target_sz(2)*padding/2):floor(target_sz(2)*padding/2)+target_sz(2),:) = nan;
% br=back_color(:,:,1);bg=back_color(:,:,2);bb=back_color(:,:,3);

try
    gm.back= gmdistribution.fit([br(:) bg(:) bb(:)],3);
catch
    try
     gm.back= gmdistribution.fit([br(:) bg(:) bb(:)],2);
    catch
     gm.back= gmdistribution.fit([br(:) bg(:) bb(:)],1);
    end
end
%target depth ditribution 
front_depth = double(get_subwindow(depthIm, pos, target_sz));
[h,w]=size(front_depth);
bin=150;
[N D]=hist(double(front_depth(:)),bin);
H = fspecial('gaussian',[1,5],0.5);
N = convn(N, H, 'same');
[P LOC]=findpeaks([0 N 0],'SORTSTR','descend','MINPEAKDISTANCE',5,'MINPEAKHEIGHT',20);
if size(LOC,2)>1
    F=max(D(LOC(1)-1),D(LOC(2)-1));
else
    F=D(LOC(1)-1);
end
front_depth(front_depth<0.9*F)=nan;
D= gmdistribution.fit(front_depth(:),1);

G1=pdf(gmdistribution(D.mu(1),D.Sigma(1)),front_depth(:));
G1=reshape(G1,[h,w]);
front_depth2=front_depth;
front_depth2(G1<0.01)=nan;

try 
    D2= gmdistribution.fit(front_depth2(:),1);
catch
    D2=D;
end
[~,cInd]=max(D2.PComponents);
sd=max(1,D2.Sigma(cInd)/sqrt(2));
gm.depth=gmdistribution(D2.mu(cInd),sd);
targetDepth=D2.mu(cInd);

%target rgb ditribution 
depthv=10*(pdf(gm.depth,front_depth(:)));
depth_seg=reshape(depthv,[h,w]);
if visualization>0,
    figure(10)
    hold on
    hist(front_depth(:),256);
    x=1:256;x=x(:);
    plot(x,5000*pdf(gm.depth,x),'r');
    hold off
end
% front_color=double(color(bbIn(2):bbIn(4),bbIn(1):bbIn(3),:));
front_color = double(get_subwindow(color, pos, target_sz));
fr=front_color(:,:,1).*(depth_seg>0.2);
fg=front_color(:,:,2).*(depth_seg>0.2);
fb=front_color(:,:,3).*(depth_seg>0.2);

ims=zeros(h,w,3);
ims(:,:,1)=fr;
ims(:,:,2)=fg;
ims(:,:,3)=fb;
fr(fr==0)=nan;
fb(fb==0)=nan;
fg(fg==0)=nan;
try
    gm.front= gmdistribution.fit([fr(:) fg(:) fb(:)],3);
catch
    try
        gm.front= gmdistribution.fit([fr(:) fg(:) fb(:)],2);
    catch
        gm.front= gmdistribution.fit([fr(:) fg(:) fb(:)],1);
    end
end
%}
end

