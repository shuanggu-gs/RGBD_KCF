function [scale, scale_model, ysf] = init_scaleTracker(im, pos, target_sz, params)

scale_sigma_factor = params.scale_sigma_factor;
scale_model_max_area = params.scale_model_max_area;
nScales = params.number_of_scales;
scale_step = params.scale_step;


cell_size = params.cell_size;
features.rgb = params.rgb;
features.depth = params.depth;


% desired scale filter output (gaussian shaped), bandwidth proportional to
% number of scales
% scale_sigma = nScales/sqrt(33) * scale_sigma_factor;
scale_sigma = nScales * scale_sigma_factor;
% scale_sigma = sqrt(prod([nScales, nScales])) * scale_sigma_factor;
% ysf = fft2(gaussian_shaped_labels(scale_sigma, [nScales, nScales]));
ss = (1:nScales^2) - ceil(nScales^2/2);
ys = exp(-0.5 * (ss.^2) / scale_sigma^2);
ysf = single(fft(ys));

% store pre-computed scale filter cosine window
if mod(nScales^2,2) == 0
    scale_window = single(hann(nScales^2+1));
    scale_window = scale_window(2:end);
else
    scale_window = single(hann(nScales^2));
end;
% scale_window = scale_window * scale_window';

% scale factors
ss = 1:nScales;
scaleFactors = scale_step.^(ceil(nScales/2) - ss);
scaleFactors = repmat(scaleFactors, nScales, 1);
scaleFactors = cat(3, scaleFactors, scaleFactors');
scaleFactors = reshape(scaleFactors, [], size(scaleFactors,3));

% compute the resize dimensions used for feature extraction in the scale
% estimation
scale_model_factor = [1,1];
if prod(target_sz) > scale_model_max_area
    scale_model_factor = sqrt(scale_model_max_area/prod(target_sz));
end
scale_model_sz = floor(target_sz .* scale_model_factor);


nScales = length(scaleFactors);
    
for s = 1:nScales
    patch_sz = floor(target_sz .* scaleFactors(s,:));
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

scale_model.num = sf_num;
scale_model.den = sf_den;



scale.scale_window = scale_window;
scale.scaleFactors = scaleFactors;
scale.model_sz = scale_model_sz;
end