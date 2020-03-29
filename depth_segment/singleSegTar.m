function [ tarListFull, scale_pos, scale_sz ] = singleSegTar(colorIm, depthIm, pos, target_sz, padding, ...
                                        gm, occDepth, occmask,visualization)
tarListFull=[];
scale_pos = [];
scale_sz = [];
%evaluate bounding box 
% a=0.3*(bbIn(3)-bbIn(1));
% bbE(1)=max(1,bbIn(1)-2*a);
% bbE(2)=max(1,bbIn(2)-a);
% bbE(3)=min(size(colorIm,2),bbIn(3)+2*a);
% bbE(4)=min(size(colorIm,1),bbIn(4)+a);
% bbE=round(bbE(:));
% color=double(colorIm(bbE(2):bbE(4),bbE(1):bbE(3),:));
% depth=depthIm(bbE(2):bbE(4),bbE(1):bbE(3));
% occmask=occmask(bbE(2):bbE(4),bbE(1):bbE(3));

window_sz = floor(target_sz * (1+padding));
color = double(get_subwindow(colorIm, pos, window_sz));
depth = double(get_subwindow(depthIm, pos, window_sz));
if ~isempty(occDepth)
    occmask = get_subwindow(occmask, pos, window_sz);
end

[H W Z]=size(color);
bbBw=zeros(H,W);
c_r=color(:,:,1);
c_g=color(:,:,2);
c_b=color(:,:,3);
% bbBw(max(1,bbIn(2)-bbE(2)):min(H,bbIn(4)-bbE(2)),max(1,bbIn(1)-bbE(1)):max(W,bbIn(3)-bbE(1)))=1;
bbBw(floor(target_sz(1)*padding/2):floor(target_sz(1)*padding/2)+target_sz(1),...
    floor(target_sz(2)*padding/2):floor(target_sz(2)*padding/2)+target_sz(2),:) = 1;

%evalu possibility
color_seg=zeros(H,W);
depth_seg=zeros(H,W);
final_seg=zeros(H,W);
[x y]=meshgrid(1:W,1:H);
k=sub2ind([H W],y,x);
f_color=pdf(gm.front,[c_r(:) c_g(:) c_b(:)]);
b_color=pdf(gm.back,[c_r(:) c_g(:) c_b(:)]);
%if bbBw(k)==1, p=0.7;else p=0.05;end
p=0.5;
color_seg(k)= p*f_color./(p*f_color+(1-p)*b_color);
depthv=10*(normpdf(depth(:),gm.depth.mu,2*gm.depth.Sigma));
depth_seg(k)=depthv(k);
if ~isempty(occDepth),
    depth_seg(k)=depth_seg(k).*occmask;
    %depthv = depthv - 10*(normpdf(depth(:),occDepth,2*gm.depth.Sigma));
end

final_seg(k)=(1.3*color_seg(k)+0.1*depth_seg(k)).*(depth_seg(k)>max(0.8*graythresh(depth_seg),0));

%process segmentation result 
   se = strel('rectangle',[14 6]);
   final_seg=imclose(final_seg,se);
   level = graythresh(final_seg);
    
   final_seg=final_seg>level;
%find connected component
   cc = bwconncomp(final_seg,8);
   sizes = zeros(length(cc.PixelIdxList),1);
   for i = 1:length(sizes)
        sizes(i) = length(cc.PixelIdxList{i});
   end
   sIndx=find(sizes>30&sizes<W*H);
   num_tar=length(sIndx);
   if num_tar == 0, tarListOut=[];
       disp('no candidate target')
       return;
   end
   findin=0;
   tarList=[];
   tarListOut=[];
   for i = 1:num_tar
      tar_mask =zeros([H W]);
      pointslocs= cc.PixelIdxList{sIndx(i)};
      intersectwithBB=bbBw(pointslocs);
      tar_mask(pointslocs)=1;
      if sum(tar_mask(:))>50;
          findin=1;
          tarBB=regionprops(tar_mask,'BoundingBox');
          tarBB=tarBB.BoundingBox;
          tarBB=[tarBB(1);tarBB(2);tarBB(1)+tarBB(3);tarBB(2)+tarBB(4)];
          tarList=[tarList, tarBB(:)];
          %bbOut=[bbE(1)-1;bbE(2)-1;bbE(1)-1;bbE(2)-1]+tarBB(:);
          %tarListOut=[tarListOut, bbOut(:)];
      end
   end
if findin==0, 
     disp(' no possible target bb in searching area') ;return;end    
%find cluster of bb
[bb_clu,cSz] = bb_smallcluster(tarList,0.4, 0.9, 2);
tarListFull=[tarList,bb_clu];   %x,y,w,h 4*n
tarListFull=[tarListFull;ones(1,size(tarListFull,2))];
%transform to frame cordinate
T=eye(4,4);
% T=[T,[bbE(1)-1;bbE(2)-1;bbE(1)-1;bbE(2)-1]];
T = [T, [floor(pos([2,1])-window_sz([2,1])/2), floor((pos([2,1])-window_sz([2,1])/2))]'];
tarListFull=T*tarListFull;

%return new cluster pos and size
scale_pos = tarListFull(1:2, :)';
scale_sz = tarListFull(3:4, :)';
scale_sz = scale_sz(:,[2,1])-scale_pos(:,[2,1]);
scale_pos = scale_pos(:,[2,1])+scale_sz/2;

if visualization>0;   
   figure(4);
   subplot(2,3,4)
   imshow(depth_seg);
   title('target depth');
   subplot(2,3,5)
   imshow(color_seg);
   title('target rgb');
   subplot(2,3,6)
   imshow(final_seg);
   title('target candidates');
   hold on;
   for j=1:size(tarList,2),
%     rectangle('Position',tarList(:,j),'LineWidth',3,'edgecolor','g');
    bb_draw(tarList(:,j),'edgecolor','g');
   end
   for j=1:size(bb_clu,2),
%     rectangle('Position',bb_clu(:,j),'LineWidth',3,'edgecolor','g');
    bb_draw(bb_clu(:,j));
   end
   hold off;
   %pause;
end
end

