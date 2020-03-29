function model = update_tracker(im, pos, params, window, model, yf)
    lambda = params.lambda;    
    cell_size = params.cell_size;
    interp_factor = params.interp_factor;
    features.rgb = params.rgb;
    features.depth = params.depth;
    kernel = params.kernel;

    
    cos_window = window.cos_window;
    window_sz = window.window_sz;
    
    model_xf = model.xf;
    model_alphaf = model.alphaf;
    %obtain a subwindow for training at newly estimated target position
    if params.scale_tracker
        currentScaleFactor = params.currentScaleFactor;    
        scalewindow_sz = currentScaleFactor .* window_sz;
        patch = get_subwindow(im, pos, scalewindow_sz);
        patch = imresize(patch, window_sz);
    else
        currentScaleFactor = params.currentScaleFactor;
        patch = get_subwindow(im, pos, currentScaleFactor*window_sz);
        patch = imresize(patch, window_sz);
%         patch = get_subwindow(im, pos, window_sz);
    end
    xf = fft2(get_features(patch, features, cell_size, cos_window));

    %Kernel Ridge Regression, calculate alphas (in Fourier domain)
    switch kernel.type
    case 'gaussian',
        kf = gaussian_correlation(xf, xf, kernel.sigma);
    case 'polynomial',
        kf = polynomial_correlation(xf, xf, kernel.poly_a, kernel.poly_b);
    case 'linear',
        kf = linear_correlation(xf, xf);
    end
    alphaf = yf ./ (kf + lambda);   %equation for fast training
    
    model_alphaf = (1 - interp_factor) * model_alphaf + interp_factor * alphaf;
    model_xf = (1 - interp_factor) * model_xf + interp_factor * xf;
    
    model.alphaf = model_alphaf;
    model.xf = model_xf;
end