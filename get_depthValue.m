function [targetDepth,  sceneDepth] = get_depthValue(im, pos, target_sz, prev_depthValue, method)
    %% kmeans
    switch method, 
        case 'kmeans'
            im = double(im)/1000;
            sceneDepth = max(im(:));
            im(im==0) = sceneDepth;     
            im_patch = get_subwindow(im, pos, target_sz);
            [IDX, C] = kmeans(im_patch(:), 2, 'EmptyAction', 'drop');
            if ~isnan(C)
                mask = zeros(size(IDX));
                mask(find(IDX == find(C == min(C(:))))) = 1;
                mask = reshape(mask, size(im_patch));

                im_patch = im_patch .* mask;
                targetDepth = sum(im_patch(:))/sum(mask(:));
%                 disp(targetDepth);
%                 disp('--------');
            else
                targetDepth = prev_depthValue;
            end
        case 'gmm'
            %target depth ditribution 
            depth = double(im);
            depth(depth==0) = 10000;
            % rescale depth
            depth = (depth-500)/8500;   %only use the data from 0.5-8m
            depth(depth<0) = 0;
            depth(depth>1) = 1;
            depth = 255*(1 - depth);
            im_patch = get_subwindow(depth, pos, target_sz);
            [h,w]=size(im_patch);
            bin=150;
            [N D]=hist(double(im_patch(:)),bin);
            H = fspecial('gaussian',[1,5],0.5);
            N = convn(N, H, 'same');
            [P LOC]=findpeaks([0 N 0],'SORTSTR','descend','MINPEAKDISTANCE',5,'MINPEAKHEIGHT',20);
            if size(LOC,2)>1
                F=max(D(LOC(1)-1),D(LOC(2)-1));
            else
                F=D(LOC(1)-1);
            end
            im_patch(im_patch<0.9*F)=nan;
            D= gmdistribution.fit(im_patch(:),1);

            G1=pdf(gmdistribution(D.mu(1),D.Sigma(1)),im_patch(:));
            G1=reshape(G1,[h,w]);
            front_depth=im_patch;
            front_depth(G1<0.01)=nan;

            try 
                D2= gmdistribution.fit(front_depth(:),1);
            catch
                D2=D;
            end
            [~,cInd]=max(D2.PComponents);
            sd=max(1,D2.Sigma(cInd)/sqrt(2));
            gm_depth=gmdistribution(D2.mu(cInd),sd);
            targetDepth=D2.mu(cInd);
            targetDepth = 255-targetDepth;
%             disp(targetDepth);
%             disp('--------');
%             disp('--------');
    end
end