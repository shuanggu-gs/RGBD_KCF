function features = init_para(feature_type, cnn_params)
    

    %%
	features.gray = false;
	features.hog = false;
    features.cn = false;
    features.deep = false;
    
%     if ismember('gray', feature_type)
%         interp_factor = 0.075;  %linear interpolation factor for adaptation
%         kernel.sigma = 0.2;  %gaussian kernel bandwidth
%         kernel.poly_a = 1;  %polynomial kernel additive term
%         kernel.poly_b = 7;  %polynomial kernel exponent
%         features.gray = true;
%         cell_size = 1;
%     end
    if ismember('hog', feature_type)
        features.hog = true;
        features.hog_orientations = 9;
    end
    if ismember('cn', feature_type)
        features.cn = true;
    end
    if ismember('deep', feature_type)
        features.deep = true;
        if ~isempty(cnn_params)
            features.fparams = init_deepfeat(cnn_params);
%             features.fparams = cnn_params;
%             features.fparams.net = load_cnn(cnn_params);
        else
            disp('no cnn settings');
            return;
        end
    end
         
end