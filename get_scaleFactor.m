function currentScaleFactor = get_scaleFactor(currentScaleFactor, prev_targetDepth, prev_sceneDepth,...
            curr_targetDepth, curr_sceneDepth)
        
%     currentScaleFactor = currentScaleFactor * sqrt(((prev_sceneDepth - curr_targetDepth)*(curr_sceneDepth - curr_targetDepth))/...
%         ((prev_sceneDepth - prev_targetDepth)*(curr_sceneDepth - prev_targetDepth)));
%     currentScaleFactor = currentScaleFactor * (prev_sceneDepth*(curr_sceneDepth - curr_targetDepth))/(curr_sceneDepth*(prev_sceneDepth - prev_targetDepth));
    
%     rate = prev_targetDepth/curr_targetDepth;
%     if abs(rate-1) <= 0.2
%         currentScaleFactor =  currentScaleFactor * rate;
%     end
    currentScaleFactor =  currentScaleFactor * prev_targetDepth / curr_targetDepth;
%     disp(currentScaleFactor);
end