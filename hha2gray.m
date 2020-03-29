function im = hha2gray(im)
    if size(im,3) == 3
        horizontal = im(:,:,1);
        height = im(:,:,2);
        angle = im(:,:,3);
        im = double(horizontal)/3 + double(height)/3 + double(angle)/3;
    end
    max_value = max(im(:));   
    im = uint8(im/max_value*255);
end