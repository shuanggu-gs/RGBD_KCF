function rgbd = readRGBD(color, depth)
% depth is uint16
%     depth = uint8(255*double(raw_depth)/double(max(raw_depth(:))));
depth = double(depth);
depth(depth==0) = 10000;
% rescale depth
depth = (depth-500)/8500;   %only use the data from 0.5-8m
depth(depth<0) = 0;
depth(depth>1) = 1;
depth = 255*(1 - depth);

rgbd = cat(3, color, depth);
end