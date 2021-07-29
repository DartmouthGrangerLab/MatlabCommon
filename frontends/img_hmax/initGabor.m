function [filterSizes,filters,sqfilter,nOrientations,filterOrientations] = initGabor (orientations)
% given orientations and receptive field sizes, returns a set of Gabor filters
%
% INPUTS:
%   orientations: a list of filter orientations in degrees, ex. [90 45 0 -45]
%
% RETURNS:
%   filterSizes: a vector (numeric), contains filter sizes for S1 units
%       filterSizes(i) = n if filters(i) is n x n (see 'filters' above)
%   filters: (for S1 units) a matrix of Gabor filters of size max_filterSizes x nFilters,
%       where max_filterSizes is the length of the largest filter &
%       nFilters is the total number of filters. Column j of 'filters' contains a
%       n_jxn_j filter, reshaped as a column vector and padded with zeros. n_j = filterSizes(j).
%   sqfilter
%   nOrientations
%   filterOrientations
% modified by Eli Bowen just for readability and to add the sqfilter, filterOrientations outputs

    RFsize = 7:2:39;     % a list of receptive field sizes for the filters
    div    = 4:-.05:3.2; % tuning parameters for the filters' "tightness"
    % ^ div: a list of scaling factors tuning the wavelength of the sinusoidal factor, 'lambda' in relation to the receptive field sizes
    % ^ numel(div) = numel(RFsize)

    nFilterSizes  = numel(RFsize);
    nOrientations = numel(orientations);
    nFilters      = nFilterSizes * nOrientations;
    filterSizes   = zeros(nFilters, 1); % vector of filter sizes
    filterOrientations = zeros(1, nFilters);
    filters       = zeros(max(RFsize)^2, nFilters);

    lambda = RFsize * 2 ./ div;
    sigma  = lambda .* 0.8;
    gamma  = 0.3; % spatial aspect ratio: 0.23 < gamma < 0.92

    for k = 1:nFilterSizes
        for r = 1:nOrientations
            theta        = orientations(r) * pi / 180;
            filterSize   = RFsize(k);
            center       = ceil(filterSize / 2);
            filterSizeL  = center - 1;
            filterSizeR  = filterSize - filterSizeL - 1;
            sigmaSquared = sigma(k) ^ 2;
            
            for i = -filterSizeL:filterSizeR
                for j = -filterSizeL:filterSizeR
                    if sqrt(i^2+j^2) > filterSize/2
                        E = 0;
                    else
                        x = i*cos(theta) - j*sin(theta);
                        y = i*sin(theta) + j*cos(theta);
                        E = exp(-(x^2+gamma^2*y^2)/(2*sigmaSquared)) * cos(2*pi*x/lambda(k));
                    end
                    f(j+center,i+center) = E;
                end
            end
           
            f = f - mean(mean(f));
            f = f ./ sqrt(sum(sum(f.^2)));
            iFilter = nOrientations*(k-1) + r;
            filters(1:filterSize^2,iFilter) = reshape(f, filterSize^2, 1);
            filterSizes(iFilter) = filterSize;
            filterOrientations(iFilter) = orientations(r);
        end
    end
    
    sqfilter = cell(1, nFilters);
    for i = 1:nFilters
        sqfilter{i} = reshape(filters(1:(filterSizes(i)^2),i), filterSizes(i), filterSizes(i));
    end
end