function currentScaleFactor = scale_tracker(im, pos, target_sz, params, scale, scale_model)
    cell_size = params.cell_size;
    lambda = params.lambda;
    currentScaleFactor = params.currentScaleFactor;
    min_scale_factor = params.min_scale_factor;
    max_scale_factor = params.max_scale_factor;
    
    features.rgb = params.rgb;
    features.depth = params.depth;
    
    scale_window = scale.scale_window;
    scaleFactors = scale.scaleFactors;
    scale_model_sz = scale.model_sz;
    
    sf_num = scale_model.num;
    sf_den = scale_model.den;
    
    nScales = length(scaleFactors);
    currentScale_sz = target_sz .* currentScaleFactor;
    
    for s = 1:nScales
        patch_sz = floor(currentScale_sz .* scaleFactors(s,:));
        im_patch = get_subwindow(im, pos, patch_sz);
        im_patch_resized = imresize(im_patch, scale_model_sz);
        
        temp = get_features(im_patch_resized, features, cell_size, []);
        temp = reshape(temp, [], size(temp,3));
        if s == 1
            out = zeros(numel(temp), nScales, 'single');
        end

        % window
        out(:,s) = temp(:) * scale_window(s);
    end
    
    % calculate the correlation response of the scale filter
    xsf = fft(out,[],2);
    scale_response = real(ifft(sum(sf_num .* xsf, 1) ./ (sf_den + lambda)));
    max_response = max(scale_response(:));
    % find the maximum scale response
    recovered_scale = find(scale_response == max_response, 1);
    disp(recovered_scale);
    % update the scale
    currentScaleFactor = currentScaleFactor .* scaleFactors(recovered_scale,:);
    currentScaleFactor(find(currentScaleFactor < min_scale_factor)) = min_scale_factor;
    currentScaleFactor(find(currentScaleFactor > max_scale_factor)) = max_scale_factor;
    
end