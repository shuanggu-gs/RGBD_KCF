function params = init_pcamatrix(im, pos, target_sz, params)
    color_im = im(:,:,1:3);
    depth_im = im(:,:,4);
    if params.rgb.deep,
        im_patch = get_subwindow(color_im, pos, target_sz);
        feature_map = get_deep_features(im_patch, params.rgb.fparams);
        feature_map = cellfun(@(x) reshape(x, [], size(x,3)), feature_map, 'uniformoutput', false);
        pca_matrix = cell(size(feature_map));
        for l = 1:size(feature_map,3)
            feat = feature_map{l};
            compressed_dim = params.rgb.fparams.compressed_dim(l);
            coeff = pca(feat);
            if compressed_dim > size(coeff, 2)
                compressed_dim = size(coeff, 2);
            end
            pca_matrix{l} = coeff(:,1:compressed_dim);
            params.rgb.fparams.compressed_dim(l) = compressed_dim;
        end
        params.rgb.fparams.pca_matrix = pca_matrix;
    end
    
    if params.depth.deep,
        im_patch = get_subwindow(depth_im, pos, target_sz);
        feature_map = get_deep_features(im_patch, params.depth.fparams);
        feature_map = cellfun(@(x) reshape(x, [], size(x,3)), feature_map, 'uniformoutput', false);
        pca_matrix = cell(size(feature_map));
        for l = 1:size(feature_map, 3)
            feat = feature_map{l};
            compressed_dim = params.depth.fparams.compressed_dim(l);
            coeff = pca(feat);
             if compressed_dim > size(coeff, 2)
                compressed_dim = size(coeff, 2);
            end
            pca_matrix{l} = coeff(:,1:compressed_dim);
            params.depth.fparams.compressed_dim(l) = compressed_dim;
        end
        params.depth.fparams.pca_matrix = pca_matrix;
    end
end