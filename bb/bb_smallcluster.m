function [ bb,cSz ] = bb_smallcluster( bbi,a, SPACE_THR, MIN_NUM_BB )
if isempty(bbi)
    bb = [];
    cSz = [];
    return;
end
bb2=bb_enlarge(bbi,a);
switch size(bb2,2)
    case 0, T = [];
    case 1, T = 1;
    case 2
        T = ones(2,1);
        if bb_distance(bb2) > SPACE_THR, T(2) = 2; end
    otherwise
        bbd = bb_distance(bb2);
        Z = linkagemex(bbd,'si');
        T = cluster(Z,'cutoff', SPACE_THR,'criterion','distance');
end
uT = unique(T);

% Merge clusters
bb = [];
cSz = [];
bb_clus=zeros(4,1);
for i = 1:length(uT)
    num_bb = sum(T == uT(i));
    if num_bb >= MIN_NUM_BB
        bb_clus(1:2,:)=min(bbi(1:2,T == uT(i)),[],2);
        bb_clus(3:4,:)=max(bbi(3:4,T == uT(i)),[],2);
        bb = [bb bb_clus];
        cSz = [cSz num_bb];
    end
end

end
function [bbl]=bb_enlargescale(bbs,s)
M=[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
bbl=s*M*bbs+bbs;
end
function [ bb ] = bb_enlarge( smallBB,a )
 x1=smallBB(1,:)-a;
 x1(x1<1)=1;
 bb(1,:)=x1;
 y1=smallBB(2,:)-a;
 y1(y1<1)=1;
 bb(2,:)=y1;
 bb(3,:)=smallBB(3,:)+a;
 bb(4,:)=smallBB(4,:)+a;
bb=round(bb(:));
end

