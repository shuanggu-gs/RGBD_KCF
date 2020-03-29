function [window, model, yf] = init_tracker(im, pos, target_sz, params)
    
    padding = params.padding;
    output_sigma_factor = params.output_sigma_factor;
    lambda = params.lambda;    
    cell_size = params.cell_size;
    
    features.rgb = params.rgb;
    features.depth = params.depth;
    kernel = params.kernel;
    
    %window size, taking padding into account
	window_sz = floor(target_sz * (1 + padding));

	
	%create regression labels, gaussian shaped, with a bandwidth
	%proportional to target size
	output_sigma = sqrt(prod(target_sz)) * output_sigma_factor / cell_size;
	yf = fft2(gaussian_shaped_labels(output_sigma, floor(window_sz / cell_size)));

	%store pre-computed cosine window
	cos_window = hann(size(yf,1)) * hann(size(yf,2))';
    
    %obtain a subwindow for training at newly estimated target position
    patch = get_subwindow(im, pos, window_sz);
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
    
    model.alphaf = alphaf;
    model.xf = xf;
    
    window.window_sz = window_sz;
    window.cos_window = cos_window;
    
end