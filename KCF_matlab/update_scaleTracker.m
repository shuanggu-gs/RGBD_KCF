function scale_model = update_scaleTracker(im, pos, target_sz, params, scale, scale_model, ysf)
    cell_size = params.cell_size;
    features.rgb = params.rgb;
    features.depth = params.depth;
    currentScaleFactor = params.currentScaleFactor;
    learning_rate = params.scale_learning_rate;
    
    scale_window = scale.scale_window;
    scaleFactors = scale.scaleFactors;
    scale_model_sz = scale.model_sz;
    
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
        out(:,s) = temp(:)*scale_window(s);
    end

    % calculate the scale filter update
    xsf = fft(out,[],2);
    sf_num = bsxfun(@times, ysf, conj(xsf));
    sf_den = sum(xsf .* conj(xsf), 1);
    
    scale_model.num = (1-learning_rate) * scale_model.num + learning_rate * sf_num;
    scale_model.den = (1-learning_rate) * scale_model.den + learning_rate * sf_den;
end