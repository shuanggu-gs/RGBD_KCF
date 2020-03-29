function [tar_response, scale_response] = scale_estimate(im, pos, target_sz, scale_pos, scale_sz, ...
                        params, orignal_model)
    
    features = params.features;
    kernel = params.kernel;
    cell_size = params.cell_size;

    xf = orignal_model.xf;
    alphaf = orignal_model.alphaf;
    
    sz = size(alphaf) * cell_size;
    
    tar_patch = get_subwindow(im, pos, target_sz);
    tar_patch = imresize(tar_patch, sz);
    tar_xf = fft2(get_features(tar_patch, features, cell_size, []));
    switch kernel.type
    case 'gaussian',
        tar_kf = gaussian_correlation(tar_xf, xf, kernel.sigma);
    case 'polynomial',
        tar_kf = polynomial_correlation(tar_xf, xf, kernel.poly_a, kernel.poly_b);
    case 'linear',
        tar_kf = linear_correlation(tar_xf, xf);
    end
    tar_response = real(ifft2(alphaf .* tar_kf));
%     tar_max_response = max(tar_response(:));
    

    scale_num = size(scale_sz, 1);
    scale_response = zeros(scale_num, size(tar_response,1), size(tar_response, 2));
%     scale_max_response = zeros(scale_num, 1);
    for s = 1:scale_num
        s_pos = scale_pos(s,:);
        s_sz = scale_sz(s,:);
        
        im_patch = get_subwindow(im, s_pos, s_sz);
        im_patch = imresize(im_patch, sz);       
        zf = fft2(get_features(im_patch, features, cell_size, []));
        switch kernel.type
        case 'gaussian',
            kzf = gaussian_correlation(zf, xf, kernel.sigma);
        case 'polynomial',
            kzf = polynomial_correlation(zf, xf, kernel.poly_a, kernel.poly_b);
        case 'linear',
            kzf = linear_correlation(zf, xf);
        end
        response = real(ifft2(alphaf .* kzf));  
        scale_response(s,:,:) = response;
%         scale_max_response(s) = max(scale_response(:));
    end
%     idx = find(scale_max_response > tar_max_response);
%     if ~isempty(idx)
%         disp('has scale transform');
%     end
end