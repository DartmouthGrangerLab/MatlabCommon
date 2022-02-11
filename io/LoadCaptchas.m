% Eli Bowen
% 12/20/2021
% INPUTS:
%   datasetStr - (char) '<datasetName>.<subset>', options:
%       'mnist'
%       'mnist.trn'
%       'mnist.tst'
%       'fashionmnist'
%       'fashionmnist.trn'
%       'fashionmnist.tst'
%       'emnist.byclass*' (see code)
%       'emnist.bymergeall'
%       'emnist.bymergetrn'
%       'emnist.bymergetst'
%       'emnist.lettersall'
%       'emnist.letterstrn'
%       'emnist.letterstst'
%       'emnist.digitsall'
%       'emnist.digitstrn'
%       'emnist.digitstst'
%       'emnist.mnistall'
%       'emnist.mnisttrn'
%       'emnist.mnisttst'
%       'noisymnisttests'
%       'noisymnisttests.bg_noise'
%       'noisymnisttests.boundary_box'
%       'noisymnisttests.box_occlusion'
%       'noisymnisttests.grid_lines'
%       'noisymnisttests.line_clutter'
%       'noisymnisttests.line_deletion'
% RETURNS:
%   img            - n_rows x n_cols x n_chan x n_images (double ranged 0 --> 1)
%   labelIdx       - 1 x n_images (int-valued numeric)
%   uniqLabel      - 1 x n_classes (cell array of chars)
%   imgSz          - 1 x 3 (int-valued numeric)
%   writer         - 1 x n_images (int-valued numeric)
%   distortionType - 1 x n_images (int-valued numeric)
%   distortionIdx  - 1 x n_images (int-valued numeric)
%   amount         - 1 x n_images (int-valued numeric)
function [img,labelIdx,uniqLabel,imgSz,writer,distortionType,distortionIdx,amount] = LoadCaptchas(datasetStr)
    validateattributes(datasetStr, 'char', {'nonempty'});
    
    % parse datasetStr
    x = strsplit(datasetStr, '.');
    datasetName = x{1};
    subset = '';
    if numel(x) > 1
        subset = x{2};
    end

    directory = fullfile(ComputerProfile.DatasetDir(), 'img_captchas', datasetName);

    img            = [];
    labelIdx       = [];
    writer         = []; % who wrote the character?
    distortionType = {};
    distortionIdx  = [];
    amount         = []; % amount of distortion

    if strcmp(datasetName, 'mnist')
        imgSz = [28,28,1];
        if strcmp(subset, 'trn')
            load(fullfile(directory, 'mnist.mat'), 'trnImg', 'trnLabel');
            img = trnImg;
            labelIdx = trnLabel(:)' + 1; % numbers 0 through 9, plus 1
        elseif strcmp(subset, 'tst')
            load(fullfile(directory, 'mnist.mat'), 'tstImg', 'tstLabel');
            img = tstImg;
            labelIdx = tstLabel(:)' + 1; % numbers 0 through 9, plus 1
        elseif isempty(subset)
            load(fullfile(directory, 'mnist.mat'), 'trnImg', 'trnLabel', 'tstImg', 'tstLabel'); % 150 s
            img = cat(4, trnImg, tstImg);
            labelIdx = cat(2, trnLabel(:)', tstLabel(:)') + 1; % numbers 0 through 9, plus 1
        else
            error('unexpected subset');
        end
        uniqLabel = {'0','1','2','3','4','5','6','7','8','9'};
    elseif strcmp(datasetName, 'fashionmnist')
        imgSz = [28,28,1];
        assert(strcmp(subset, 'trn') || strcmp(subset, 'tst') || isempty(subset));
        if strcmp(subset, 'trn') || isempty(subset)
            x = importdata(fullfile(directory, 'fashion-mnist_train.csv'));
            assert(strcmp(x.colheaders{1}, 'label'));
            img = x.data(:,2:end)' ./ 255;
            labelIdx = x.data(:,1)' + 1; % these numbers index into uniqueLabel
        end
        if strcmp(subset, 'tst') || isempty(subset)
            x = importdata(fullfile(directory, 'fashion-mnist_test.csv'));
            assert(strcmp(x.colheaders{1}, 'label'));
            img = cat(2, img, x.data(:,2:end)' ./ 255);
            labelIdx = cat(2, labelIdx, x.data(:,1)' + 1); % these numbers index into uniqueLabel
        end
        img = permute(reshape(img, imgSz(1), imgSz(2), imgSz(3), []), [2,1,3,4]);
        uniqLabel = {'tshirtortop','trouser','pullover','dress','coat','sandal','shirt','sneaker','bag','ankleboot'};
    elseif strcmp(datasetName, 'emnist')
        imgSz = [28,28,1];
        if startsWith(subset, 'byclass')
            load(fullfile(directory, 'matlab', 'emnist-byclass.mat'), 'dataset'); % 814,255 characters, 62 UNbalanced classes (0 --> 9, A --> Z, a --> z)
            indexAdjustment = 1; % uses 0-based indexing
        elseif startsWith(subset, 'bymerge')
            load(fullfile(directory, 'matlab', 'emnist-bymerge.mat'), 'dataset');
            error('untested');
        elseif startsWith(subset, 'letters')
            load(fullfile(directory, 'matlab', 'emnist-letters.mat'), 'dataset'); % 145,600 characters, 26 balanced classes (case-insensitive!)
            indexAdjustment = 0; % uses 1-based indexing
        elseif startsWith(subset, 'digits')
            load(fullfile(directory, 'matlab', 'emnist-digits.mat'), 'dataset'); % 280,000 characters, 10 balanced classes (0 --> 9)
            indexAdjustment = 1; % uses 0-based indexing
        elseif startsWith(subset, 'mnist')
            load(fullfile(directory, 'matlab', 'emnist-mnist.mat'), 'dataset');
            error('untested');
        else
            error('unexpected subset');
        end
        assert(contains(subset, 'trn') || contains(subset, 'tst') || contains(subset, 'all'));
        if contains(subset, 'trn') || contains(subset, 'all')
            img = im2double(reshape(dataset.train.images', imgSz(1), imgSz(2), imgSz(3), []));
            labelIdx = dataset.train.labels + indexAdjustment;
            writer = dataset.train.writers;
        end
        if contains(subset, 'tst') || contains(subset, 'all')
            img = cat(2, img, im2double(reshape(dataset.test.images', imgSz(1), imgSz(2), imgSz(3), [])));
            labelIdx = cat(2, labelIdx, dataset.test.labels + indexAdjustment);
            writer = cat(2, writer, dataset.test.writers);
        end
        
        uniqLabel = cellstr(char(dataset.mapping(:,2)))';
        
        if startsWith(subset, 'byclass')
            drop = false(1, numel(labelIdx));
            if contains(subset, 'digits')
                drop = (labelIdx > 10); % uniqLabel should be digits THEN capitals THEN lower case
            elseif contains(subset, 'letters')
                drop = (labelIdx <= 10); % uniqLabel should be digits THEN capitals THEN lower case
                labelIdx = labelIdx - 10;
                uniqLabel = uniqLabel(11:end);
            elseif contains(subset, 'upper')
                drop = (labelIdx <= 10) | (labelIdx >= 37); % uniqLabel should be digits THEN capitals THEN lower case
                labelIdx = labelIdx - 10;
                uniqLabel = uniqLabel(11:end);
            elseif contains(subset, 'lower')
                drop = (labelIdx <= 36); % uniqLabel should be digits THEN capitals THEN lower case
                labelIdx = labelIdx - 36;
                uniqLabel = uniqLabel(37:end);
            end
            img(:,:,:,drop) = [];
            labelIdx(drop)  = [];
            writer(drop)    = [];
        end
    elseif strcmp(datasetName, 'noisymnisttests')
        imgSz = [28,28,1];
        if ~isempty(subset)
            assert(any(strcmp(distortionType, subset)));
        end
        distortionType = {'bg_noise','boundary_box','box_occlusion','grid_lines','line_clutter','line_deletion'};
        for i = 1 : numel(distortionType)
            if ~isempty(subset) && ~strcmp(subset, distortionType{i})
                continue;
            end
            if isfile(fullfile(directory, [distortionType{i},'.mat']))
                load(fullfile(directory, [distortionType{i},'.mat']), 'distortionImg', 'distortionLabelIdx', 'distortionAmt');
            else
                distortionImg      = [];
                distortionLabelIdx = [];
                distortionAmt      = [];
                unzip(fullfile(directory, [distortionType{i},'.zip']), fullfile(ComputerProfile.CacheDir(), 'noisymnisttests'));
                for c = 1 : 10
                    listing1 = dir(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests', distortionType{i}, '0', num2str(c-1), '*.png'));
                    listing2 = dir(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests', distortionType{i}, '1', num2str(c-1), '*.png'));
                    listing3 = dir(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests', distortionType{i}, '2', num2str(c-1), '*.png'));
                    classImg = zeros(imgSz(1), imgSz(2), imgSz(3), numel(listing1) + numel(listing2) + numel(listing3));
                    classAmt = NaN(1, numel(listing1) + numel(listing2) + numel(listing3));
                    for j = 1 : numel(listing1) % for each image in this dir
                        classImg(:,:,:,j) = im2double(rgb2gray(imread(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests', distortionType{i}, '0', num2str(c-1), listing1(j).name))));
                        classAmt(j) = 0;
                    end
                    for j = 1 : numel(listing2) % for each image in this dir
                        classImg(:,:,:,numel(listing1) + j) = im2double(rgb2gray(imread(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests', distortionType{i}, '1', num2str(c-1), listing2(j).name))));
                        classAmt(numel(listing1) + j) = 1;
                    end
                    for j = 1 : numel(listing3) % for each image in this dir
                        classImg(:,:,:,numel(listing1) + numel(listing2) + j) = im2double(rgb2gray(imread(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests', distortionType{i}, '2', num2str(c-1), listing3(j).name))));
                        classAmt(numel(listing1) + numel(listing2) + j) = 2;
                    end
                    distortionImg      = cat(4, distortionImg, classImg);
                    distortionLabelIdx = cat(2, distortionLabelIdx, c .* ones(1, size(classImg, 4)));
                    distortionAmt      = cat(2, distortionAmt, classAmt);
                end
                rmdir(fullfile(ComputerProfile.CacheDir(), 'noisymnisttests'), 's');
                save(fullfile(directory, [distortionType{i},'.mat']), 'distortionImg', 'distortionLabelIdx', 'distortionAmt', '-v7.3');
            end
            
            img           = cat(4, img, distortionImg);
            labelIdx      = cat(2, labelIdx, distortionLabelIdx);
            distortionIdx = cat(2, distortionIdx, i .* ones(1, numel(distortionLabelIdx)));
            amount        = cat(2, amount, distortionAmt);
        end
        uniqLabel = {'0','1','2','3','4','5','6','7','8','9'};
    else
        error('unexpected dataset');
    end

    % validate
    assert(all(size(img) == [imgSz,size(img, 4)]));
    assert(min(labelIdx) > 0 && max(labelIdx <= numel(uniqLabel)));
end