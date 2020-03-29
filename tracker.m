function [positions, fps] = tracker(params)
time = 0;
%% color images / depth images / HHA images
image_path = params.image_path;
color_path = image_path.color;
depth_path = image_path.depth;
% HHA_path = image_path.HHA;

img_files = params.img_files;

color_files = img_files.colorSet;
depth_files = img_files.depthSet;
% HHA_files = img_files.HHASet;
pos = floor(params.init_pos);
target_sz = floor(params.wsize);

scale_step = params.scale_step;

frame_size = length(color_files);
positions = zeros(frame_size, 4);

for it_frame = 1:frame_size
    raw_color = imread(fullfile(color_path, color_files(it_frame).name));
    raw_depth = imread(fullfile(depth_path, depth_files(it_frame).name));
    rgbd = readRGBD(raw_color, raw_depth);
    tic;
    %%  init tracker
    if it_frame  == 1
                
        if params.rgb.deep || params.depth.deep
            params = init_pcamatrix(rgbd, pos, target_sz, params);
        end
        [window, model, yf] = init_tracker(rgbd, pos, target_sz, params);
        if params.scale_tracker
            params.min_scale_factor = scale_step ^ ceil(log(max(5 ./ window.window_sz)) / log(scale_step));
            params.max_scale_factor = scale_step ^ floor(log(min([size(rgbd,1) size(rgbd,2)] ./ target_sz)) / log(scale_step));
            params.currentScaleFactor = [1,1];
    %         params.currentScaleFactor = 1;
%             [scale, scale_model, ysf] = init_scaleTracker(rgbd, pos, target_sz, params);
        end
        params.currentScaleFactor = 1;
        [curr_targetDepth, curr_sceneDepth] = get_depthValue(raw_depth, pos, target_sz, [], params.get_depth);
    else
        %% start tracker----get position
        [pos, response] = pos_tracker(rgbd, pos, params, window, model);
        if params.scale_tracker
            params.currentScaleFactor = scale_tracker(rgbd, pos, target_sz, params, scale, scale_model);
            disp(params.currentScaleFactor);
        end
        prev_targetDepth = curr_targetDepth;
        prev_sceneDepth = curr_sceneDepth;
        [curr_targetDepth, curr_sceneDepth] = get_depthValue(raw_depth, pos, target_sz, prev_targetDepth, params.get_depth);
        params.currentScaleFactor = get_scaleFactor(params.currentScaleFactor, prev_targetDepth, prev_sceneDepth,...
            curr_targetDepth, curr_sceneDepth);
        
        disp(params.currentScaleFactor);
        
        if params.visualization
            figure(5),
            subplot(121), imagesc(response);
            subplot(122), mesh(1:size(response,2), 1:size(response,1), response);
        end
        %% update tracker        
        model = update_tracker(rgbd, pos, params, window, model, yf);
        if params.scale_tracker
            scale_model = update_scaleTracker(rgbd, pos, target_sz, params, scale, scale_model, ysf);
        end
    end
    
    %% save tracker box
    if params.scale_tracker
        box_sz = target_sz .* params.currentScaleFactor;
    else
        box_sz = target_sz * params.currentScaleFactor;
    end
    positions(it_frame,:) = [pos, box_sz];
    time = time + toc;
    fps = frame_size / time;
    
    if params.visualization
        tracker_box = [pos([2,1])-box_sz([2,1])/2, box_sz([2,1])]; 
        figure(1);
        imshow(raw_color);
        rectangle('Position', tracker_box, 'EdgeColor', 'r');
        drawnow
    end
    
end    
    
end