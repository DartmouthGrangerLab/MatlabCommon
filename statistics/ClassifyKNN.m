% performs KNN classification
% if interested in cross-validation, just call ClassifyCrossvalidate(data, label, nFolds, 'knn', ...)
% INPUTS:
%   K - scalar (int-valued numeric) - number of neighbors to use
%   trnData - nFeatures x nTrnPts (numeric or logical)
%   tstData - nFeatures x nTstPts (numeric or logical)
%   trnLabel - 1 x nTrnPts (cell, numeric, or logical) - "ground truth" label for each training point
%   distance - char or function_handle - @(X,Y) function handle or one of 'cityblock', 'chebychev', 'correlation', 'cosine', 'euclidean', 'hamming', 'jaccard', 'mahalanobis', 'minkowski', 'seuclidean' (not sqeuclidean), 'spearman'
% RETURNS:
%   predLabel - 1 x nTstPts (same format as trnLabel)
%   predStrength - 1 x nTstPts (double ranged 0-->1) - a measure of how strongly KNN believes in the prediction in predLabel (SLOW TO COMPUTE) (ONLY returned for euclidean or cosine distance)
function [predLabel,predStrength] = ClassifyKNN (K, trnData, tstData, trnLabel, distance)
    validateattributes(K, 'numeric', {'nonempty','scalar','positive','integer'});
    validateattributes(trnData, {'numeric','logical'}, {'nonempty','2d','nonnan','ncols',numel(trnLabel)});
    validateattributes(tstData, {'numeric','logical'}, {'nonempty','2d','nonnan','nrows',size(trnData, 1)});
    validateattributes(trnLabel, {'cell','numeric','logical'}, {'nonempty','vector'});
    validateattributes(distance, {'char','function_handle'}, {'nonempty'});
    assert((isnumeric(trnData) && isnumeric(tstData)) || (islogical(trnData) && islogical(tstData))); % inputs must be same datatype

    nTstPts = size(tstData, 2);
    
    if K == 1 && strcmpi(distance, 'euclidean')
        idx = NaN(1, nTstPts); % index of the training image that best matches each test image
        for i = 1:nTstPts
            if isnumeric(trnData)
                [~,idx(i)] = min(sum((trnData - tstData(:,i)).^2, 1)); % implicit expansion
            else % binary values
                [~,idx(i)] = min(sum(trnData ~= tstData(:,i), 1)); % implicit expansion
            end
        end
        predLabel = trnLabel(idx);
    elseif K == 1 && strcmpi(distance, 'cosine')
        idx = NaN(1, nTstPts); % index of the training image that best matches each test image
        trnL2Norm = vecnorm(double(trnData), 2, 1); % 1 x nTrnClips
        tstL2Norm = vecnorm(double(tstData), 2, 1); % 1 x nTstClips
        for i = 1:nTstPts
            if isnumeric(trnData)
                [~,idx(i)] = max(sum(trnData .* tstData(:,i), 1) ./ (trnL2Norm.*tstL2Norm(i))); % implicit expansion
            else % binary values
                [~,idx(i)] = max(sum(trnData & tstData(:,i), 1) ./ (trnL2Norm.*tstL2Norm(i))); % implicit expansion
            end
        end
        predLabel = trnLabel(idx);
    else
        error('TODO: validate (never tested)');
        model = fitcknn(trnData, trnLabel, 'ClassNames', uniqueLabels, 'NumNeighbors', K, 'Distance', distance);
        predLabel = predict(model, tstData);
    end
    
    predStrength = [];
    if nargout() > 1 && (strcmpi(distance, 'euclidean') || strcmpi(distance, 'cosine'))
        diameter = min(nTstPts, K * 10); % in units of number of points
        w = 1 ./ (1:1/K:1+(diameter-1)/K); % weight for each point, after they're ranked from closest to furthest
        w = w ./ sum(w); % normalize so max is 1, min is 0
        predStrength = NaN(size(predLabel));
        if strcmpi(distance, 'euclidean')
            for i = 1:nTstPts
                if isnumeric(trnData)
                    [~,idx] = sort(sum((trnData - tstData(:,i)).^2, 1), 'ascend'); % implicit expansion
                else % binary values
                    [~,idx] = sort(sum(trnData ~= tstData(:,i), 1), 'ascend'); % implicit expansion
                end
                temp = (predLabel(i) == trnLabel(idx(1:diameter)));
                predStrength(i) = sum(temp(:)' .* w(:)');
            end
        elseif strcmpi(distance, 'cosine')
            trnL2Norm = vecnorm(double(trnData), 2, 1); % 1 x nTrnClips
            tstL2Norm = vecnorm(double(tstData), 2, 1); % 1 x nTstClips
            for i = 1:nTstPts
                if isnumeric(trnData)
                    [~,idx] = sort(sum(trnData .* tstData(:,i), 1) ./ (trnL2Norm.*tstL2Norm(i)), 'descend'); % implicit expansion
                else % binary values
                    [~,idx] = sort(sum(trnData & tstData(:,i), 1) ./ (trnL2Norm.*tstL2Norm(i)), 'descend'); % implicit expansion
                end
                temp = (predLabel(i) == trnLabel(idx(1:diameter)));
                predStrength(i) = sum(temp(:)' .* w(:)');
            end
        end
    end
end