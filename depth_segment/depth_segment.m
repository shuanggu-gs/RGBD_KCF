function [] = depth_segment(color, depth, pos, target_sz, padding)
    window_sz = floor(target_sz * (1 + padding));
    depth_patch = get_subwindow(depth, pos, window_sz);
    color_patch = get_subwindow(color, pos, window_sz);
    target_patch = get_subwindow(depth, pos, target_sz);
    [counts,binLocations] = imhist(target_patch);
    counts(1) = 0;  % value 0 do not count
    peak = find(counts == max(counts(:)));
    
    for i = peak:length(counts)
        if counts(i) == 0;
            peak_r = i-1;
            break;
        end
    end
    for i = peak:-1:1
        if counts(i) == 0;
            peak_l = i+1;
            break;
        end
    end
    
    bw_patch = zeros(size(depth_patch));
    bw_patch(depth_patch>=binLocations(peak_l) & depth_patch<=binLocations(peak_r)) = 1;
    bw_patch = im2bw(bw_patch);
    
    CC = bwconncomp(bw_patch);
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [biggest,idx] = max(numPixels);
    bw_patch(CC.PixelIdxList{idx}) = 1;
    
    figure, imshow(bw_patch);
    
    
    mask = cat(3, bw_patch, bw_patch, bw_patch);
    seg_color = uint8(mask) .* color_patch;
        
    figure, imshow(seg_color);
end