% Given an image, returns C1 & S1 unit responses
% args:
%     img: a 2-dimensional matrix, the input image must be grayscale and of type 'double'
% 
%   c1Scale: (for C1 units) a vector, defines the scale bands, a group of
%       filter sizes over which a local max is taken to get C1 unit responses.
%       ex. c1Scale = [1 k num_filters+1] means 2 bands, the first with
%       filters(:,1:k-1) and the second with filters(:,k:num_filters).
%       If N bands, make length(c1Scale) = N+1.
%
%   c1Space: (for C1 units) a vector, defines the spatial pooling range of
%       each scale band, ex. c1Space(i) = m means that each C1 unit response in
%       band i is obtained by taking a max over a neighborhood of m x m S1 units.
%       If N bands, make length(c1Space) = N.
%
%   sqfilter - (cell)
%
%   filters: (for S1 units) a matrix of Gabor filters of size max_filterSizes
%       x nFilters, where max_filterSizes is the length of the largest filter &
%       nFilters is the total number of filters. Column j of 'filters' contains a
%       n_jxn_j filter, reshaped as a column vector and padded with zeros. n_j = filterSizes(j).
%
%   isIncludeBorder: scalar (logical) - defines border treatment for 'img'
%
% RETURNS:
%     c1: a cell array [1 nBands], contains the C1 responses for img
%     s1: a cell array [1 nBands], contains the S1 responses for img
% modified by Eli Bowen for readability and:
%   for speed / memory fragmentation (preallocate variables etc.)
%   changed s1 return structure slightly (it's never used by hmax outside this function)
%   switched return value order for efficiency
function [s1,c1] = C1 (img, c1Space, c1Scale, sqfilter, isIncludeBorder)
%     c1OL = 2; % c1OL: (for C1 units) a scalar, defines the overlap between C1 units
%     % ^ In scale band i, C1 unit responses are computed every c1Space(i)/c1OL
    
    nBands = numel(c1Scale) - 1;
    nScalesPerBand = numel(c1Scale(1):(c1Scale(2) - 1));
    nScales = nBands * nScalesPerBand;
    nOrientations = floor(numel(sqfilter) / nScales);

    %% compute all filter responses (s1)
    iUFilterIdx = 0;
    s1 = cell(nBands, nScalesPerBand, nOrientations);
    for b = 1:nBands
        for s = 1:nScalesPerBand
            for r = 1:nOrientations
                iUFilterIdx = iUFilterIdx + 1;
                s1{b,s,r} = ApplyGaborFilter(img, sqfilter{iUFilterIdx}, isIncludeBorder);
            end
        end
    end

    %% Calculate local pooling (c1)
    if nargout() > 1
        c1 = cell(1, nBands);
        for b = 1:nBands
            poolSize = c1Space(b);

            halfpool = poolSize / 2;
            rowIdx = 1:halfpool:size(s1{b,1,1}, 1);
            colIdx = 1:halfpool:size(s1{b,1,1}, 2);
            c1{b} = zeros(numel(rowIdx), numel(colIdx), nOrientations); % size determined by Eli reading through maxFilter()

            for r = 1:nOrientations
                % (1) pool over scales within band
                c1PreFilter = zeros(size(s1{b,1,r}));
                for s = 1:nScalesPerBand
                    c1PreFilter = max(c1PreFilter, s1{b,s,r});
                end

                % (2) pool over local neighborhood
                c1{b}(:,:,r) = maxFilter(c1PreFilter, poolSize);
            end
        end
    end
end