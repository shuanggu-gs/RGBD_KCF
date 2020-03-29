function  [gm, depthCurr] = update_distribution(depth, pos, target_sz, padding, gm, depthPrev)
    bin = 150;    
    window_sz = floor(target_sz * (1+padding));
    depth_tar = get_subwindow(depth, pos, window_sz);
        
    [N D]=hist(double(depth_tar(:)),bin);
    binsize=D(2)-D(1);
    H = fspecial('gaussian',[1,5],0.5);
    N = convn(N, H, 'same');
    [P LOC]=findpeaks([0 N 0],'SORTSTR','descend','MINPEAKDISTANCE',2,'MINPEAKHEIGHT',20);
    if isempty(LOC)
        return;
    end
    
    
    %find closest peak to tld.depth
    L=min(length(LOC),4);
    sd=gm.depth.Sigma;
    if isnan(depthPrev),
        depthCurr=max(D(LOC(1:2)-1));
    else
        [new_target_depth,~,~]=findnearest(depthPrev,D(LOC(1:L)-1));
        if abs(new_target_depth-depthPrev)<1.5*sd || abs(new_target_depth-depthPrev)<100,
            depthCurr=new_target_depth;
        else
            depthCurr=depthPrev;
        end
    end
    gm.depth = gmdistribution(depthCurr, gm.depth.Sigma);
end

function [y,n,lastpeak]=findnearest(x,array)
n=0;
if isempty (array), 
    y=-99999;
    lastpeak=1;
    return ; 
end
mind=999999;
for i=1:length(array)
    d=abs(x-array(i));
    if d<mind,
        mind=d;
        n=i;
    end
end
y=array(n);
if y==max(array),
    lastpeak=1;
else
    lastpeak=0;
end
end