clc;
close all;

setup();

base_path = '/media/gs/study/gushuang/data/ValidationSet';
% base_path = '/media/gs/study/gushuang/data/PrincetonTrackingBenchmark/EvaluationSet';


%%  params initialization
    params.padding = 1.5;  %extra area surrounding the target
	params.lambda = 1e-4;  %regularization
	params.output_sigma_factor = 0.1;  %spatial bandwidth (proportional to target)
	params.interp_factor = 0.02;
    params.scale_sigma_factor = 1/4;        % standard deviation for the desired scale filter output
    params.learning_rate = 0.025;			% tracking model learning rate (denoted "eta" in the paper)
    params.number_of_scales = 5;           % number of scale levels (denoted "S" in the paper)
    params.scale_step = 1.02;               % Scale increment factor (denoted "a" in the paper)
    params.scale_model_max_area = 512;
    params.scale_learning_rate = 0.025;
    params.cell_size = 4;
    params.scale_tracker = 0;
    params.segpadding = 0.3;
    params.get_depth = 'kmeans';    %{'gmm', 'kmeans'}
    
    params.visualization = 1;
    params.debug = 1;
        
    cnn_params.nn_name = 'imagenet-vgg-pad.mat';    % Name of the network
    cnn_params.output_layer = [3 14];               % Which layers to use
    cnn_params.downsample_factor = [2 1];           % How much to downsample each output layer
%     cnn_params.compressed_dim = [16 64];            % Compressed dimensionality of each output layer
    cnn_params.input_size_mode = 'adaptive';        % How to choose the sample size
    cnn_params.input_size_scale = 1;                % Extra scale factor of the input samples to the network 
    cnn_params.pca_matrix = [];
    cnn_params.normalize_size = 1;
    cnn_params.normalize_dim = 1;
    cnn_params.use_gpu = 1;
    cnn_params.gpu_id = [];
    cnn_params.debug = params.debug;
    
    kernel.type = 'gaussian';   %kernel_type: {'linear', 'polynomial', 'gaussian'}
    kernel.sigma = 0.5;
    kernel.poly_a = 1;
    kernel.poly_b = 9; 
    params.kernel = kernel;
    
    rgb_feature_type = {'deep'}; %feature_type: {'hog', 'cn', 'deep'}
    depth_feature_type = {'deep'};
    
    

    
 %% load images information
    if params.debug
        image_path = choose_video(base_path);
        [images, pos, target_sz, ground_truth, images_path, image_name] = load_image_info(image_path);
        params.init_pos = floor(pos) + floor(target_sz/2);
        params.wsize = floor(target_sz);
        params.img_files = images;
        params.image_path = images_path;
        
        cnn_params.sample_sz = floor(target_sz*(1+params.padding));
        cnn_params.compressed_dim = [16 64];
        params.rgb = init_para(rgb_feature_type, cnn_params);
        cnn_params.compressed_dim = [16 32];
        params.depth = init_para(depth_feature_type, cnn_params);
        [positions, fps] = tracker(params);
%         boxes = [positions(:,[2,1]) - positions(:,[4,3])/2, positions(:,[2,1]) + positions(:,[4,3])/2];
%         saveResult('tracker', 'Ours', image_name, boxes);
        disp(fps);
        
    else
        total_fps = 0;
        fileSet = dir(base_path);
        for it_dir = 1:length(fileSet)
            if strcmp(fileSet(it_dir).name, '.') || strcmp(fileSet(it_dir).name, '..') || strcmp(fileSet(it_dir).name, '.DS_Store')
                continue;
            end
            %% load rgbd images and init files 
            disp([fileSet(it_dir).name ' is Start!']);
            image_path = fullfile(base_path, fileSet(it_dir).name);
            [images, pos, target_sz, ground_truth, images_path] = load_image_info(image_path);            
            params.init_pos = floor(pos) + floor(target_sz/2);
            params.wsize = floor(target_sz);
            params.img_files = images;
            params.image_path = images_path;
            %% track
            cnn_params.sample_sz = floor(target_sz*(1+params.padding));
            cnn_params.compressed_dim = [16 64];
            params.rgb = init_para(rgb_feature_type, cnn_params);
            cnn_params.compressed_dim = [16 32];
            params.depth = init_para(depth_feature_type, cnn_params);  
            [positions, fps] = tracker(params);
            total_fps = total_fps + fps;
            %% save results
            boxes = [positions(:,[2,1]) - positions(:,[4,3])/2, positions(:,[2,1]) + positions(:,[4,3])/2];
            saveResult('tracker', '2017_6_28_RGB_HOG_DEEP+Depth_HOG_DEEP(one tracker)', fileSet(it_dir).name, boxes);
            disp(fps);
            disp([fileSet(it_dir).name ' is Done!']);
        end
        disp('All Done!');
        disp('Average FPS:');
        disp(total_fps/95);
    end
 
