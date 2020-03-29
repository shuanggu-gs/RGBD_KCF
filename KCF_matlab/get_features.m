function x = get_features(im, features, cell_size, cos_window)
%GET_FEATURES
%   Extracts dense features from image.
%
%   X = GET_FEATURES(IM, FEATURES, CELL_SIZE)
%   Extracts features specified in struct FEATURES, from image IM. The
%   features should be densely sampled, in cells or intervals of CELL_SIZE.
%   The output has size [height in cells, width in cells, features].
%
%   To specify HOG features, set field 'hog' to true, and
%   'hog_orientations' to the number of bins.
%
%   To experiment with other features simply add them to this function
%   and include any needed parameters in the FEATURES struct. To allow
%   combinations of features, stack them with x = cat(3, x, new_feat).
%
%   Joao F. Henriques, 2014
%   http://www.isr.uc.pt/~henriques/

    color_im = im(:,:,1:3);
    depth_im = im(:,:,4);
    x = [];
	
    if features.rgb.hog,
		%HOG features, from Piotr's Toolbox
        gray_im = rgb2gray(color_im);
		x = double(fhog(single(gray_im) / 255, cell_size, features.rgb.hog_orientations));
		x(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
    end	
    if features.rgb.cn,        
        im_patch = imresize(color_im, [floor(size(color_im,1)/cell_size), floor(size(color_im,2)/cell_size)]);
        out = get_cn_features(single(im_patch), 'cn', []);
        if isempty(x)
            x = out;
        else
            x = cat(3, x, out);
        end
    end
    
    if features.rgb.deep,
        feature_map = get_deep_features(color_im, features.rgb.fparams);
        %Do pca projection
        feature_size = cellfun(@(x) size(x) , feature_map, 'uniformoutput', false);
        feature_map = cellfun(@(x) reshape(x, [], size(x,3)), feature_map, 'uniformoutput', false);        
%         feature_size = cell(size(feature_map));
        for l = 1:size(feature_map, 3)
            if isa(feature_map{l}, 'gpuArray')
                feature = gather(feature_map{l});                
                pca_matrix = gather(features.rgb.fparams.pca_matrix{l});
            end
            feature = feature*pca_matrix;
            feature_map{l} = reshape(feature, [feature_size{l}(1:2), size(feature, 2)]);
        end
        
        patch_sz = [floor(size(color_im,1)/cell_size), floor(size(color_im,2)/cell_size)];
        feat = cellfun(@(x) imresize(x, patch_sz), feature_map, 'uniformoutput', false);
        feat = cell2mat(feat);
        if isempty(x)
            x = feat;
        else
            x = cat(3, x, feat);
        end
    end
    
    
    if features.depth.hog,
        out = double(fhog(single(depth_im) / 255, cell_size, features.depth.hog_orientations));
		out(:,:,end) = [];  %remove all-zeros channel ("truncation feature")
        if isempty(x)
            x = out;
        else
            x = cat(3, x, out);
        end
    end
    if features.depth.deep,
        feature_map = get_deep_features(depth_im, features.depth.fparams);
        %Do pca projection
        feature_size = cellfun(@(x) size(x) , feature_map, 'uniformoutput', false);
        feature_map = cellfun(@(x) reshape(x, [], size(x,3)), feature_map, 'uniformoutput', false);        
%         feature_size = cell(size(feature_map));
        for l = 1:size(feature_map, 3)
            if isa(feature_map{l}, 'gpuArray')
                feature = gather(feature_map{l});                
                pca_matrix = gather(features.depth.fparams.pca_matrix{l});
            end
            feature = feature*pca_matrix;
            feature_map{l} = reshape(feature, [feature_size{l}(1:2), size(feature, 2)]);
        end
        
        patch_sz = [floor(size(depth_im,1)/cell_size), floor(size(depth_im,2)/cell_size)];
        feat = cellfun(@(x) imresize(x, patch_sz), feature_map, 'uniformoutput', false);
        feat = cell2mat(feat);
        if isempty(x)
            x = feat;
        else
            x = cat(3, x, feat);
        end
    end
    
    
    
	%process with cosine window if needed
	if ~isempty(cos_window),
		x = bsxfun(@times, x, cos_window);
	end
	
end
