% Eli Bowen
% 11/30/2019
% copied and enhanced from LSRExperiments() (Eli Bowen, 7/2/2019)
% USAGE:
%   model = ClusterInit(trnData, K, 'clusterer', 'distance', init);
%   [model,responsesToTrnData] = Cluster(model, trnData, do_fuzzy, maxIter);
%   responsesToTstData = ClustResponse(model, tstData);
% INPUTS:
%   model - struct, result of ClustInit()
%   data
%   do_fuzzy - scalar (logical)
%   maxIter - scalar (numeric)
function [model,data] = Cluster(model, data, do_fuzzy, maxIter)
    K = size(model.mu, 1);
    distance = model.distance;
    if strcmp(distance, 'cosine')
        % fix zeroish-length vectors
        Xnorm = realsqrt(sum(data.^2, 2));
        tIdxs = find(Xnorm <= eps(max(Xnorm)));
        data = [data,zeros(size(data, 1), 1)];
        data(tIdxs,end) = 1;
    end

    if strcmp(model.clusterer, 'kmeans')
        [idx,model.mu,~] = KMeans(model, data, distance, maxIter, do_fuzzy, false);
    elseif strcmp(model.clusterer, 'gmm')
        assert(~do_fuzzy);
        [idx,model] = GMM(data, K, maxIter, model);
    else
        error('unknown clusterer');
    end

    counts = CountNumericOccurrences(idx, 1:K);

    if any(counts == 0)
        warning(['removing ',num2str(sum(counts==0)),' (of ',num2str(K),') clusters for having 0 members']);

        if strcmp(model.clusterer, 'kmeans')
            model.mu(counts==0,:) = [];
        elseif strcmp(model.clusterer, 'gmm')
            if strcmp(model.modelType, 'matlabbuiltin')
                error('TODO');
            elseif strcmp(model.modelType, 'em_matlabcentral')
                model.mu(:,counts==0)      = [];
                model.sigma(:,:,counts==0) = [];
                model.w(counts==0)         = [];
            else
                error('invalid model.modelType');
            end
        else
            error('unknown clusterer');
        end
    end

    %% calculate responses
    data = ClustResponse(model, data);
end
