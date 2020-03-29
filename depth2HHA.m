function HHA = depth2HHA(color, raw_depth, K)
    %depth image pre-processing ---> bitshift(mm)
    raw_depth = bitor(bitshift(raw_depth,-3), bitshift(raw_depth,16-3));
    %fill depth image
    depth = fill_depth_cross_bf(color, double(raw_depth)/1000);
    HHA = HHA_feature(raw_depth, depth, K);
end