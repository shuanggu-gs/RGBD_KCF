function [pos, response] = pos_tracker(im, pos, params, window, model)
     
    cell_size = params.cell_size;
    features.rgb = params.rgb;
    features.depth = params.depth;
    kernel = params.kernel;

    
    cos_window = window.cos_window;
    window_sz = window.window_sz;
    
    model_xf = model.xf;
    model_alphaf = model.alphaf;
    %obtain a subwindow for detection at the position from last
    %frame, and convert to Fourier domain (its size is unchanged)
    if params.scale_tracker
        currentScaleFactor = params.currentScaleFactor;
        scalewindow_sz = currentScaleFactor .* window_sz;
        patch = get_subwindow(im, pos, scalewindow_sz);    
        patch = imresize(patch, window_sz);
    else
        currentScaleFactor = params.currentScaleFactor;
        patch = get_subwindow(im, pos, currentScaleFactor*window_sz);
        patch = imresize(patch, window_sz);
    end
    zf = fft2(get_features(patch, features, cell_size, cos_window));
    
    %calculate response of the classifier at all shifts
    switch kernel.type
    case 'gaussian',
        kzf = gaussian_correlation(zf, model_xf, kernel.sigma);
    case 'polynomial',
        kzf = polynomial_correlation(zf, model_xf, kernel.poly_a, kernel.poly_b);
    case 'linear',
        kzf = linear_correlation(zf, model_xf);
    end
    response = real(ifft2(model_alphaf .* kzf));  %equation for fast detection
    
    %target location is at the maximum response. we must take into
    %account the fact that, if the target doesn't move, the peak
    %will appear at the top-left corner, not at the center (this is
    %discussed in the paper). the responses wrap around cyclically.
    [vert_delta, horiz_delta] = find(response == max(response(:)), 1);
%     if vert_delta > size(zf,1) / 2,  %wrap around to negative half-space of vertical axis
%         vert_delta = vert_delta - size(zf,1);
%     end
%     if horiz_delta > size(zf,2) / 2,  %same for horizontal axis
%         horiz_delta = horiz_delta - size(zf,2);
%     end
%     pos = pos + cell_size * [vert_delta - 1, horiz_delta - 1]; 
    
    pos = pos + cell_size * [vert_delta - floor(size(zf, 1)/2),...
            horiz_delta - floor(size(zf, 2)/2)];
end