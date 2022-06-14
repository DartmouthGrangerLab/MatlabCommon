% Eli Bowen 5/2022
% INPUTS
%   datasetName - (char)
%   path - OPTIONAL (char) directory in which to find the dataset file(s)
% RETURNS
%   dataset - (struct) with fields:
%       .uniq_class - (cellstr) 'multi' means multiple classes in same frame (not currently handled)
%       .class_idx  - n_files x 1 (numeric index) index into uniq_class
%       .box        - 4 x n_files (numeric) pixel coordinates of the box [?,?,?,?]
%       .uniq_video - (cellstr)
%       .vid_idx    - n_files x 1 (numeric index) index into uniq_video
%       .frame      - n_files x 1 (int-valued numeric) frame number within the video
%       .img        - n_rows x n_cols x n_chan x n_files (uint8)
% USAGE
%   dataset = io.LoadSonar('teledyne-reson');
function dataset = LoadSonar(datasetName, path)
    validateattributes(datasetName, {'char'}, {'nonempty','vector'}, 1);
    if ~exist('path', 'var') || isempty(path)
        path = fullfile(ComputerProfile.DatasetDir(), 'sonar', datasetName);
    end
    
    dataset = struct();
    
    if strcmp(datasetName, 'teledyne-reson')
        if isfile(fullfile(path, 'dataset.mat'))
            load(fullfile(path, 'dataset.mat'), 'dataset');
%             dataset.file_name  = h5read(fullfile(path, 'dataset.h5'), '/file_name');
%             dataset.uniq_class = h5read(fullfile(path, 'dataset.h5'), '/uniq_class');
%             dataset.class_idx  = h5read(fullfile(path, 'dataset.h5'), '/class_idx');
%             dataset.box        = h5read(fullfile(path, 'dataset.h5'), '/box');
%             dataset.img        = h5read(fullfile(path, 'dataset.h5'), '/img');
        else
            % load labels
            unzipDir = fullfile(ComputerProfile.CacheDir(), ['loadsonar_',GetMD5(now, 'array', 'hex')]);
            unzip(fullfile(path, 'FLS_CLAHE_PASCAL_VOC_Labels.zip'), unzipDir);

            [n_files,filePath] = CountFileType(unzipDir, 'xml', true);
            [~,fileName,~] = fileparts(filePath);

            class = cell(n_files, 1);
            dataset.box = zeros(4, n_files);
            for i = 1 : n_files
                text = fileread(filePath{i});
                temp = lower(extractBetween(text, '<name>', '</name>'));
                if isempty(temp)
                    dataset.box(:,i) = [NaN,NaN,NaN,NaN];
                elseif numel(temp) == 1
                    class(i) = temp; % not curly braces, really
                    xmin = str2double(extractBetween(text, '<xmin>', '</xmin>'));
                    xmax = str2double(extractBetween(text, '<xmax>', '</xmax>'));
                    ymin = str2double(extractBetween(text, '<ymin>', '</ymin>'));
                    ymax = str2double(extractBetween(text, '<ymax>', '</ymax>'));
                    dataset.box(:,i) = [xmin,xmax,ymin,ymax];
%                 elseif numel(unique(temp)) == 1 % this is a multi-object image but all images are the same class
%                     class{i} = temp{1}; % not curly braces, really
%                     dataset.box(:,i) = [NaN,NaN,NaN,NaN];
                else % this is a multi-object image with multiple classes
                    class{i} = 'multi';
                    dataset.box(:,i) = [NaN,NaN,NaN,NaN]; % for now, omit these
                end
            end
            
            mask = ~cellfun(@isempty, class);
            dataset.class_idx = NaN(n_files, 1);
            [dataset.uniq_class,~,dataset.class_idx(mask)] = unique(class(mask));

            rmdir(unzipDir, 's');

            % load images
            labelMap = containers.Map(fileName, 1:n_files);
            imgSz = [604,1044,1]; % smallest img size in dataset
            dataset.img = zeros(imgSz(1), imgSz(2), imgSz(3), n_files, 'uint8');
            zipFiles = {'aircraft_carrier.zip','breakwater.zip','cape_fear.zip','coiled_target.zip','hole.zip','multiaspect.zip','multiaspect45.zip','nav_buoy.zip','newport_bridge.zip','prudence.zip'};
            for i = 1 : numel(zipFiles)
                unzipDir = fullfile(ComputerProfile.CacheDir(), ['loadsonar_',GetMD5(now, 'array', 'hex')]);
                unzip(fullfile(path, zipFiles{i}), unzipDir);

                [n_files,filePath] = CountFileType(unzipDir, 'png', true);
                [~,currFileName,~] = fileparts(filePath);

                for j = 1 : n_files % for each image in this path
                    if isKey(labelMap, currFileName{j})
                        idx = labelMap(currFileName{j});
                        
                        currImg = imread(filePath{j});
                        % the images were apparently colorized using a heatmap that's similar to matlab's "hot"
                        % the below code inverts the hot colormap - mean(hot(), 2) is a linear scale!
                        currImg = uint8(mean(double(currImg), 3)); % don't use rgb2gray() - see above
                        
                        dataset.box(:,idx) = dataset.box(:,idx) .* imgSz(2) ./ size(currImg, 2); % rescale the bounding box too
                        
                        dataset.img(:,:,:,idx) = imresize(currImg, imgSz(1:2)); % rescale to the smallest size
                    end
                end

                rmdir(unzipDir, 's');
            end
            dataset.img(end-23:end,:,:,:) = []; % remove some blank padding
            
            % extract video/frame metadata
            lastSepIdx = cellfun(@(x)find(x=='_', 1, 'last'), fileName);
            vidName = cell(size(fileName));
            dataset.frame = zeros(n_files, 1);
            for i = 1 : numel(fileName)
                vidName{i} = fileName{i}(1:lastSepIdx(i)-1);
                dataset.frame(i) = str2double(fileName{i}(lastSepIdx(i)+1:end)); % video frame number
            end
            [dataset.uniq_video,~,dataset.vid_idx] = unique(vidName);
            
            save(fullfile(path, 'dataset.mat'), 'dataset', '-v7.3');
            % below code doesn't work rn
%             h5create(fullfile(path, 'dataset.h5'), '/uniq_class', size(dataset.uniq_class));
%             h5write(fullfile(path, 'dataset.h5'), '/uniq_class', dataset.uniq_class);
%             h5write(fullfile(path, 'dataset.h5'), '/class_idx',  dataset.class_idx);
%             h5write(fullfile(path, 'dataset.h5'), '/box',        dataset.box);
%             h5write(fullfile(path, 'dataset.h5'), '/uniq_video', dataset.uniq_video);
%             h5write(fullfile(path, 'dataset.h5'), '/vid_idx',    dataset.vid_idx);
%             h5write(fullfile(path, 'dataset.h5'), '/frame',      dataset.frame);
%             h5write(fullfile(path, 'dataset.h5'), '/img',        dataset.img);
        end
        
        % remove frames with no labels
        mask = ~isnan(dataset.class_idx);
        dataset.class_idx = dataset.class_idx(mask);
        dataset.box       = dataset.box(:,mask);
        dataset.vid_idx   = dataset.vid_idx(mask);
        dataset.frame     = dataset.frame(mask);
        dataset.img       = dataset.img(:,:,:,mask);
    else
        error('unexpected datasetName');
    end
end