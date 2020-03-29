function im_3c = gray2rgb(im)
[M N] = size(im);
im_3c = zeros(M, N, 3);
 
for x = 1 : M
   for y = 1 : N
      if im(x, y) <= 127                                 % R
          im_3c(x, y, 1) = 0;
      elseif im(x, y) <= 191
          im_3c(x, y, 1) = 4 * im(x, y) - 510;
      else
          im_3c(x, y, 1) = 255;
      end
       
      if im(x, y) <= 63                                  % G
          im_3c(x, y, 2) = 254 - 4 * im(x, y);
      elseif im(x, y) <= 127
          im_3c(x, y, 2) = 4 * im(x, y) - 254;
      elseif im(x, y) <= 191
          im_3c(x, y, 2) = 255;
      else
          im_3c(x, y, 2) = 1022 - 4 * im(x, y);
      end
       
      if im(x, y) <= 63                                 % B
          im_3c(x, y, 3) = 255;
      elseif im(x, y) <= 127
          im_3c(x, y, 3) = 510 - 4 * im(x, y);
      else
          im_3c(x, y, 3) = 0;
      end
   end
end
 
imshow(uint8(im_3c));