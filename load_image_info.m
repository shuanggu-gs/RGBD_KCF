function [images, pos, target_sz, ground_truth, images_path, image_name] =...
                                    load_image_info(image_path)
                  
    images_path.color = fullfile(image_path, 'rgb');
    images_path.depth = fullfile(image_path, 'depth_mm');
    images_path.HHA = fullfile(image_path, 'HHA');
                                
    images.colorSet = dir(fullfile(images_path.color, '*.png'));
    images.depthSet = dir(fullfile(images_path.depth, '*.png'));
    images.HHASet = dir(fullfile(images_path.HHA, '*.png'));
    
    init_rect = load(fullfile(image_path,  'init.txt'));  %x,y,w,h
    pos = init_rect([2,1]);
    target_sz = init_rect([4,3]);
    
    
       
    image_name = regexp(image_path, '/', 'split');
    image_name = image_name(end-1);
    image_name = image_name{1};
    
    if exist(fullfile(image_path, [image_name '.txt']), 'file')
        gt = load(fullfile(image_path,[image_name '.txt']));
        ground_truth = [gt(:,[2,1])+gt(:,[4,3])/2, gt(:,[4,3])];
    else
        ground_truth = [];
    end
end