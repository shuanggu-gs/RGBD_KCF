function occ = occ_handle(it_frame, color, depth, pos, target_sz, para, model,...
                                             rgb_responses, depth_responses)
    features = para.features;
    cell_size = para.cell_size;
                                        
    occ = false;
    avgRgb_res = sum(rgb_responses(1:it_frame-1))/double(it_frame-1);
    avgDepth_res = sum(depth_responses(1:it_frame-1))/double(it_frame-1);
    rgb_response = rgb_responses(it_frame);
    depth_response = depth_responses(it_frame);
%     if rgb_response/avgRgb_res < 0.8 && depth_response/avgDepth_res < 0.8
    if rgb_response < 0.6 && depth_response < 0.6           
        
%% kmeans model
         %fill hole
%          depth = fill_depth_cross_bf(color, double(depth));
         %kmeans 3 clases: occluder, object, background
        color_obj = get_subwindow(color, pos, target_sz);
        depth_obj = get_subwindow(depth, pos, target_sz);
%         depth_obj = imcrop(depth, box);
        x = double(depth_obj(:));
        [Idx, C] = kmeans(x, 3);
        x = reshape(Idx, size(depth_obj));
        background_id = find(C == max(C(:)));
        background_num = length(find(Idx == background_id));
        min_id = find(C == min(C(:)));
        min_num = length(find(Idx == min_id));
        if double(min_num)/double(length(Idx)) > 0.85 && double(background_num)/double(length(Idx)) > 0.05
%             object_id = min_id;
            occ = false;
        else
            occluder_id = min_id;
            occluder_mask = zeros(size(depth_obj));
            occluder_mask(x == occluder_id) = 1;
            occluder_mask = im2bw(occluder_mask);
            occluder = regionprops(occluder_mask,'basic');
%             figure;
%             imshow(occluder_mask);
%             hold on;
%             centriods = cat(1, occluder.Centroid);
%             for i = 1:size(occluder)
%                 plot(centriods(i,1),centriods(i,2),'b*');
%                 rectangle('Position',[occluder(i).BoundingBox],'LineWidth',2,'LineStyle','--','EdgeColor','r')
%             end
            occluder_area = [occluder.Area];
            max_occluder_box = occluder(find(occluder_area == max(occluder_area))).BoundingBox;
%             max_occluder_pos = occluder(find(occluder_area == max(occluder_area))).Centroid;
            max_occluder_pos = max_occluder_box(1:2) + max_occluder_box(3:4)/2;
            max_occluder_sz = max_occluder_box(3:4);
           
            figure(2);
            imshow(occluder_mask);
            hold on;
            plot(max_occluder_pos(1), max_occluder_pos(2), 'b*');
            rectangle('Position', max_occluder_box, 'LineWidth',2,'LineStyle','--','EdgeColor','r');
            occluder_xcorr = get_xcorr(color_obj, max_occluder_pos([2,1]), max_occluder_sz([2,1]), para, model);
            
%             occluder_patch = get_subwindow(color_obj, max_occluder_pos', max_occluder_sz');
%             occluder_feature = get_features(occluder_patch, features, cell_size, []);
%             feature_nocos = model.feature_nocos;
%             occluder_xcorr = 0.0;
%             for i = 1:size(occluder_feature,3)
%                 C = xcorr2(feature_nocos(:,:,i),occluder_feature(:,:,i));
%                 occluder_xcorr = occluder_xcorr + max(abs(C(:)));
%             end
                       
            
            object_id = 6 - occluder_id - background_id;
            object_mask = zeros(size(depth_obj));
            object_mask(x == object_id) = 1;
            object_mask = im2bw(object_mask);
            object = regionprops(object_mask,'basic');
%             figure;
%             imshow(object_mask);
%             hold on;
%             centriods = cat(1, object.Centroid);
%             for i = 1:size(object)
%                 plot(centriods(i,1),centriods(i,2),'b*');
%                 rectangle('Position',[object(i).BoundingBox],'LineWidth',2,'LineStyle','--','EdgeColor','r')
%             end
            object_area = [object.Area];
            max_object_box = object(find(object_area == max(object_area))).BoundingBox;
%             max_object_pos = object(find(object_area == max(object_area))).Centroid;
            max_object_pos = max_object_box(1:2) + max_object_box(3:4)/2;
            max_object_sz = max_object_box(3:4);
            object_xcorr = get_xcorr(color_obj, max_object_pos([2,1]), max_object_sz([2,1]), para, model);
%             object_patch = get_subwindow(color_obj, max_object_pos', max_object_sz');
%             object_feature = get_features(object_patch, features, cell_size, []);
%             feature_nocos = model.feature_nocos;
%             object_xcorr = 0.0;
%             for i = 1:size(occluder_feature,3)
%                 C = xcorr2(feature_nocos(:,:,i),object_feature(:,:,i));
%                 object_xcorr = object_xcorr + max(abs(C(:)));
%             end
            
            figure(3);
            imshow(object_mask);
            hold on;
            plot(max_object_pos(1), max_object_pos(2), 'b*');
            rectangle('Position', max_object_box, 'LineWidth',2,'LineStyle','--','EdgeColor','r');
            
            
            disp(occluder_xcorr);
            disp(object_xcorr);
            if object_xcorr > occluder_xcorr
                occ = true;
            else
                occ = false;
            end
        end

    end
end