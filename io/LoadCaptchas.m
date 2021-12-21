% Eli Bowen
% 12/20/2021
% INPUTS:
%   datasetName - char
%   subset      - char
% RETURNS:
%   img         - n_rows x n_cols x n_chan x n_images (double ranged 0 --> 1)
%   labelIdx    - 1 x n_images (int-valued numeric)
%   uniqueLabel - 1 x n_classes (cell array of chars)
function [img,labelIdx,uniqueLabel] = LoadCaptchas(datasetName, subset)
    validateattributes(datasetName, 'char', {'nonempty'});
    validateattributes(subset,      'char', {'nonempty'});
    assert(strcmp(subset, 'trn') || strcmp(subset, 'tst') || strcmp(subset, 'all'));

    directory = fullfile(ComputerProfile.DatasetDir(), 'img_captchas');

    if strcmp(datasetName, 'mnist')
        imgSz = [28,28,1];
        uniqueLabel = {'0','1','2','3','4','5','6','7','8','9'};
    elseif strcmp(datasetName, 'fashionmnist')
        imgSz = [28,28,1];
        uniqueLabel = {'tshirtortop','trouser','pullover','dress','coat','sandal','shirt','sneaker','bag','ankleboot'};
    else
        error('unexpected dataset');
    end

    img      = [];
    labelIdx = [];

    if strcmp(datasetName, 'mnist')
        if strcmp(subset, 'trn')
            load(fullfile(directory, 'mnist', 'mnist.mat'), 'trnImg', 'trnLabel');
            img = trnImg;
            labelIdx = trnLabel(:)' + 1; % numbers 0 through 9, plus 1
        elseif strcmp(subset, 'tst')
            load(fullfile(directory, 'mnist', 'mnist.mat'), 'tstImg', 'tstLabel');
            img = tstImg;
            labelIdx = tstLabel(:)' + 1; % numbers 0 through 9, plus 1
        elseif strcmp(subset, 'all')
            load(fullfile(directory, 'mnist', 'mnist.mat'), 'trnImg', 'trnLabel', 'tstImg', 'tstLabel'); % 150 s
            img = cat(4, trnImg, tstImg);
            labelIdx = cat(2, trnLabel(:)', tstLabel(:)') + 1; % numbers 0 through 9, plus 1
        else
            error('unexpected subset');
        end
    elseif strcmp(datasetName, 'fashionmnist')
        if strcmp(subset, 'trn') || strcmp(subset, 'all')
            x = importdata(fullfile(directory, 'fashionmnist', 'fashion-mnist_train.csv'));
            assert(strcmp(x.colheaders{1}, 'label'));
            img = x.data(:,2:end)' ./ 255;
            labelIdx = x.data(:,1)' + 1; % these numbers index into uniqueLabel
        end
        if strcmp(subset, 'tst') || strcmp(subset, 'all')
            x = importdata(fullfile(directory, 'fashionmnist', 'fashion-mnist_test.csv'));
            assert(strcmp(x.colheaders{1}, 'label'));
            img = cat(2, img, x.data(:,2:end)' ./ 255);
            labelIdx = cat(2, labelIdx, x.data(:,1)' + 1); % these numbers index into uniqueLabel
        end
        img = permute(reshape(img, imgSz(1), imgSz(2), imgSz(3), []), [2,1,3,4]);
    else
        error('unexpected dataset');
    end

    % validate
    assert(all(size(img) == [imgSz,size(img, 4)]));
    assert(min(labelIdx) >= 0 && max(labelIdx <= numel(uniqueLabel)));
end