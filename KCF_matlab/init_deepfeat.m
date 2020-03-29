function fparams = init_deepfeat(cnn_params)
    size_mode = 'odd_cells';

    fparams = cnn_params;
    fparams.output_layer = sort(fparams.output_layer);

    % Set default parameters
    if ~isfield(fparams, 'input_size_mode')
        fparams.input_size_mode = 'adaptive';
    end
    if ~isfield(fparams, 'input_size_scale')
        fparams.input_size_scale = 1;
    end
    if ~isfield(fparams, 'downsample_factor')
        fparams.downsample_factor = ones(1, length(fparams.output_layer));
    end

    % load the network
    net = load_cnn(fparams);
    fparams.net = net;

    % find the dimensionality of each layer
    fparams.nDim = net.info.dataSize(3, fparams.output_layer+1)';

    % find the stride of the layers
    if isfield(net.info, 'receptiveFieldStride')
        net_info_stride = cat(2, [1; 1], net.info.receptiveFieldStride);
    else
        net_info_stride = [1; 1];
    end

    % compute the cell size of the layers (takes down-sampling factor
    % into account)
    fparams.cell_size = net_info_stride(1, fparams.output_layer+1)' .* fparams.downsample_factor';
    
    % Set default cell size
    if ~isfield(fparams, 'cell_size')
        fparams.cell_size = 1;
    end
    
    % Set default penalty
    if ~isfield(fparams, 'penalty')
        fparams.penalty = zeros(length(fparams.nDim),1);
    end
    
    % This ugly code sets the image sample size to be used for extracting the
    % features. It then computes the data size (size of the features) and the
    % image support size (the corresponding size in the image).
    scale = fparams.input_size_scale;

    new_sample_sz = fparams.sample_sz;

    % First try decrease one
    net_info = net.info;

    if ~strcmpi(size_mode, 'same') && strcmpi(fparams.input_size_mode, 'adaptive')
        orig_sz = net.info.dataSize(1:2,end)' / fparams.downsample_factor(end);

        if strcmpi(size_mode, 'exact')
            desired_sz = orig_sz + 1;
        elseif strcmpi(size_mode, 'odd_cells')
            desired_sz = orig_sz + 1 + mod(orig_sz,2);
        end

        while desired_sz(1) > net_info.dataSize(1,end)
            new_sample_sz = new_sample_sz + [1, 0];
            net_info = vl_simplenn_display(net, 'inputSize', [round(scale * new_sample_sz), 3 1]);
        end
        while desired_sz(2) > net_info.dataSize(2,end)
            new_sample_sz = new_sample_sz + [0, 1];
            net_info = vl_simplenn_display(net, 'inputSize', [round(scale * new_sample_sz), 3 1]);
        end
    end



    % Sample size to be input to the net
    scaled_sample_sz = round(scale * fparams.sample_sz);

    if isfield(net_info, 'receptiveFieldStride')
        net_info_stride = cat(2, [1; 1], net_info.receptiveFieldStride);
    else
        net_info_stride = [1; 1];
    end

    net_stride = net_info_stride(:, fparams.output_layer+1)';
    total_feat_sz = net_info.dataSize(1:2, fparams.output_layer+1)';

    shrink_number = max(2 * ceil((net_stride(end,:) .* total_feat_sz(end,:) - scaled_sample_sz) ./ (2 * net_stride(end,:))), 0);

    deepest_layer_sz = total_feat_sz(end,:) - shrink_number;
    scaled_support_sz = net_stride(end,:) .* deepest_layer_sz;

    % Calculate output size for each layer
    cnn_output_sz = round(bsxfun(@rdivide, scaled_support_sz, net_stride));
    fparams.start_ind = floor((total_feat_sz - cnn_output_sz)/2) + 1;
    fparams.end_ind = fparams.start_ind + cnn_output_sz - 1;

    

    % Set the input size
%     fparams.net = set_cnn_input_size(net, feature_info.img_sample_sz);

    if fparams.use_gpu
        if isempty(fparams.gpu_id)
            gpuDevice();
        elseif fparams.gpu_id > 0
            gpuDevice(fparams.gpu_id);
        end
        fparams.net = vl_simplenn_move(fparams.net, 'gpu');
    end
end