% Given an image, returns C1 & S1 unit responses
% INPUTS:
%   img: a 2-dimensional matrix, the input image must be grayscale and of type 'double'
%   c1Space: a vector, defines the spatial pooling range of each scale band
%       ex. c1Space(i) = m means that each C1 unit response in
%       band i is obtained by taking a max over a neighborhood of m x m S1 units
%       If N bands, make length(c1Space) = N
%   sqfilter - nOrientations x nFilters (cell) - matrix of Gabor filters
%   isIncludeBorder - scalar (logical) - defines border treatment for 'img'
%   doNormalizeGabors - scalar (logical)
% RETURNS:
%   s1: 1 x nBands (cell) - contains the S1 responses for img
%   c1: 1 x nBands (cell) - contains the C1 responses for img
% modified by Eli Bowen for readability and:
%   for speed / memory fragmentation (preallocate variables etc.)
%   changed s1 return structure slightly (it's never used by hmax outside this function)
%   switched return value order for efficiency
function [s1,c1] = C1 (img, c1Space, sqfilter, isIncludeBorder, doNormalizeGabors)
%     c1OL = 2; % c1OL: (for C1 units) a scalar, defines the overlap between C1 units
%     % ^ In scale band i, C1 unit responses are computed every c1Space(i)/c1OL
    nBands = numel(c1Space); % numel(c1Space) == numel(c1Scale) - 1
    nScalesPerBand = size(sqfilter, 2) / nBands; % was calculated as numel(c1Scale(1):(c1Scale(2) - 1))
    nOrientations = size(sqfilter, 1);

    %% compute all filter responses (s1)
    iUFilterIdx = 0;
    s1 = cell(nBands, nScalesPerBand, nOrientations);
    for b = 1:nBands
        for s = 1:nScalesPerBand
            iUFilterIdx = iUFilterIdx + 1;
            for r = 1:nOrientations
                s1{b,s,r} = ApplyGaborFilter(img, sqfilter{r,iUFilterIdx}, isIncludeBorder, doNormalizeGabors, true);
            end
        end
    end

    %% calculate local pooling (c1)
    if nargout() > 1
        c1 = cell(1, nBands);
        for b = 1:nBands
            poolSize = c1Space(b);

            halfpool = poolSize / 2;
            rowIdx = 1:halfpool:size(s1{b,1,1}, 1);
            colIdx = 1:halfpool:size(s1{b,1,1}, 2);
            c1{b} = zeros(numel(rowIdx), numel(colIdx), nOrientations, 'like', img); % size determined by Eli reading through maxFilter()

            for r = 1:nOrientations
                % (1) pool over scales within band
                c1PreFilter = zeros(size(s1{b,1,r}), 'like', img);
                for s = 1:nScalesPerBand
                    c1PreFilter = max(c1PreFilter, s1{b,s,r});
                end

                % (2) pool over local neighborhood
                c1{b}(:,:,r) = maxFilter(c1PreFilter, poolSize);
            end
        end
    end
end