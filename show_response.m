function response_map = show_response(im, pos, response, cell_size)
    response_map = zeros(size(im,1), size(im,2));
    
    for vert_delta = 1:size(response, 1)
        for horiz_delta = 1:size(response, 2)
            i = vert_delta;
            j = horiz_delta;
            if i > size(response,1) / 2,  %wrap around to negative half-space of vertical axis
                i = i - size(response,1);
            end
            if j > size(response,2) / 2,  %same for horizontal axis
                j = j - size(response,2);
            end
            new_pos = pos + cell_size * [i - 1, j - 1];
            response_map(max(1,new_pos(1)):min(new_pos(1)+cell_size, size(im,1)), max(1,new_pos(2)):min(new_pos(2)+cell_size, size(im,2))) = response(vert_delta, horiz_delta);
        end
    end
    figure(11), imagesc(response_map);
    figure(12), mesh(1:size(im,2), 1:size(im,1), response_map);
end