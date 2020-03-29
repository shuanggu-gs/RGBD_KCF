function saveResult(tracker_type, zipname, filename, boxes)
    path = '/media/gs/study/gushuang/data/PrincetonTrackingBenchmark/';
    if ~exist(fullfile(path, zipname),'dir')
        mkdir(fullfile(path, zipname));
    end
    switch tracker_type
        case 'tracker'
            if ~exist(fullfile(path, zipname, 'tracker'), 'dir')
                mkdir(fullfile(path, zipname, 'tracker'));
            end
            result_name = fullfile(path, zipname, 'tracker',[filename '.txt']);
        case 'rgb'
            if ~exist(fullfile(path, zipname, 'rgb'), 'dir')
                mkdir(fullfile(path, zipname, 'rgb'));
            end
            result_name = fullfile(path, zipname, 'rgb',[filename '.txt']);
            
        case 'depth'
            if ~exist(fullfile(path, zipname, 'depth'), 'dir')
                mkdir(fullfile(path, zipname, 'depth'));
            end
            result_name = fullfile(path, zipname, 'depth',[filename '.txt']);
            
    end
    
    dlmwrite(result_name, boxes);
end