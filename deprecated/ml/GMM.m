% Eli Bowen 11/18/2017
% reimplementation of pseudocode "OME" from:
% INPUTS:
%   data    - N x D
%   K       - scalar (numeric) num clusters
%   maxIter - maximum number of iterations
%   R       - number of initial categories
%   initType
function [clustMemberships,model] = GMM(data, K, maxIter, initType)
    eta = 0.005; %learning rate

    %% way 1: matlab built-in way (still takes forever)
%     t1 = tic();
%     options = statset('MaxIter', maxIter, 'Display', 'iter');
%     model = fitgmdist(data, K, 'CovarianceType', 'full', 'SharedCovariance', false, 'Options', options);
%     model.modelType = 'matlabbuiltin';
%     clustMemberships = cluster(gmfit, data);
% %     mahalDist = mahal(model, X0);
%     disp(['way1 took ',num2str(toc(t1)),'s']);

    %% way 2
    %from https://www.mathworks.com/matlabcentral/fileexchange/26184-em-algorithm-for-gaussian-mixture-model--em-gmm-
%     t1 = tic();
    [clustMemberships,model,~] = MixGaussEm(data', K, maxIter, initType);
    model.modelType = 'em_matlabcentral';
%     [clustMemberships,R] = MixGaussPred(data', model);
%     disp(['way2 took ',num2str(toc(t1)),'s']);

    %% way 3
%     t1 = tic();
%     %initialization
%     N = size(data, 1);
%     D = size(data, 2);
%     sigma = cell(K, 1); %covariance matrices (DxD each)
%     for r = 1:K
%         sigma{r} = 0.2 * eye(D);
%     end
%     mix = ones(K, 1) ./ K; %mixing probability of each category
%     
%     if isstruct(initType) % init with a model
%         assert(~any(isnan(initType.mu(:))) && ~any(isnan(initType.sigma(:))) && ~any(isnan(initType.w(:))), 'initType better not contain NaN!');
%         centroids = initType;
%     elseif strcmp(initType, 'supervised')
%         centroids = InitKMeansSupervised(data, K, labels);
%     elseif strcmp(initType, 'random') || strcmp(initType, 'sample') %sample is for compatability with matlab's built in kmeans
% %         centroids = zeros(K, D); %means (1xD each)
% %         for r = 1:K
% %             centroids(r,:) = 3 .* randn(1, D);
% %         end
%         centroids = InitKMeansRandomly(data, K);
%     elseif strcmp(initType, 'furthestfirst')
%         centroids = InitKMeansFurthestFirst(data, K, kernel);
%     elseif strcmp(initType, 'kmeans++') || strcmp(initType, 'plus') %plus is for compatability with matlab's built in kmeans
%         centroids = InitKMeansPlusPlus(data, K, kernel);
%     else
%         error('invalid param initType');
%     end
%     
%     clustMemberships = zeros(1, N);
%     p = zeros(K, 1); %p(r) is the likelihood of the data point given category r
% %     p = zeros(K, N); %p(r) is the likelihood of the data point given category r
%     dLog2PiDiv2 = D * log(2*pi) / 2;
%     for trial = 2:maxIter
%         oldLabels = clustMemberships;
%         
%         tic;
%         for i = 1:N
%             %% (i) get the input stimulus D
%             dataPtMinCentroids = data(i,:) - centroids;
% 
%             %% (ii) calculate the likelihood of D for each category r
%             for r = 1:K
%                 p(r) = mix(r) * myMvnpdf(dataPtMinCentroids(r,:), sigma{r}, dLog2PiDiv2); %Pr(D|M(r,:),C{R})
%             end
% 
%             %% (iii) calculate the responsibility for each category r
%             p = p ./ sum(p); %Kx1: Resp(r) is the responsibility of the data point for category r
% 
%             %% (iv) update the parameters for each category r
%             centroids = centroids + (eta .* p) .* dataPtMinCentroids;
%             for r = 1:K
% %                 centroids(r,:) = centroids(r,:) + (eta * Resp(r)) .* temp(r,:);
%                 sigma{r} = sigma{r} + (eta * p(r)) .* (dataPtMinCentroids(r,:)*dataPtMinCentroids(r,:)' - sigma{r});
%             end
% 
%             %% (v) update the mixing probability for winning category rhat
%             [~,clustMemberships(i)] = max(p); %winner
%             mix(clustMemberships(i)) = mix(clustMemberships(i)) + eta;
% 
%             %% (vi) ensure mixing probabilities sum to 1
%             mix = mix ./ sum(mix);
%         end
% 
% %         %% (ii) calculate the likelihood of D for each category r
% %         for r = 1:K
% %             p(r,:) = mix(r) .* myMvnpdfBulk(data, centroids(r,:), C{r}, dLog2PiDiv2); %Pr(D|M(r,:),C{R})
% %         end
% % 
% %         %% (iii) calculate the responsibility for each category r
% %         p = p ./ sum(p, 1); %Kx1: Resp(r) is the responsibility of the data point for category r
% %         
% %         %% (iv) update the parameters for each category r
% %         for i = 1:N
% %             dataPtMinCentroids = data(i,:) - centroids;
% %             centroids = centroids + (eta .* p(:,i)) .* dataPtMinCentroids;
% %             for r = 1:K
% %                 C{r} = C{r} + (eta * p(r,:)) .* (dataPtMinCentroids(r,:)*dataPtMinCentroids(r,:)' - C{r});
% %             end
% %         end
% % %         for r = 1:K
% % %             Numerator = zeros(1, D);
% % %             for i = 1:N
% % %                 Numerator = Numerator + Gamma(r,i) .* data(i,:);
% % %             end
% % %             centroids(r,:) = Numerator ./ sum(Gamma(r,:));
% % %         end
% % %         for r = 1:K
% % %             for j = 1:D
% % %                 Variances(r,j) = 0;
% % %                 for i = 1:N
% % %                     Variances(r,j) = Variances(r,j) + Gamma(r,i) * (data(i,j) - centroids(r,j))^2;
% % %                 end
% % %                 Variances(r,j) = Variances(r,j) ./ sum(Gamma(r,:)) + ZERO_OFFSET;
% % %             end
% % %         end
% %         
% %         %% (v) update the mixing probability for winning category rhat
% %         [~,clustMemberships] = max(p, [], 1); %winner
% %         mix(clustMemberships) = mix(clustMemberships) + eta;
% %         error('^validate');
% % 
% %         %% (vi) ensure mixing probabilities sum to 1
% %         mix = mix ./ sum(mix);
%         
%         time1 = toc();
%         
%         numChanged = sum(oldLabels ~= clustMemberships);
%         disp(['iter ',num2str(trial),' changed=',num2str(100.0 * numChanged / N),'% timing = ',num2str(time1),' s']);
%     end
%     disp(['way3 took ',num2str(toc(t1)),'s']);
end


% modified from matlab's own code (to be more efficient)
function [y] = myMvnpdf(XMinusMu, sigma, dLog2PiDiv2)
    [R,err] = chol(sigma); %ripped from matlabs own 'cholcov()' for efficiency
    assert(err == 0); % Make sure Sigma is a valid covariance matrix
    
    quadform = sum((XMinusMu/R) .^ 2); % The quadratic form is the inner products of the standardized data
    y = exp(-0.5*quadform - sum(log(diag(R))) - dLog2PiDiv2);
end
function [y] = myMvnpdfBulk(MixGaussEmXBulk, Mu, Sigma, dLog2PiDiv2)
    [R,err] = chol(Sigma); %ripped from matlabs own 'cholcov()' for efficiency
    assert(err == 0); % Make sure Sigma is a valid covariance matrix
    
    quadform = sum(((XBulk-Mu)/R) .^ 2, 2); % The quadratic form is the inner products of the standardized data
    y = exp(-0.5*quadform - sum(log(diag(R))) - dLog2PiDiv2);
end


% perform EM algorithm for fitting the Gaussian mixture model
% Input: 
%   X: D x N data matrix
%   init: k (1 x 1) number of components or label (1 x n, 1<=label(i)<=k) or model structure
% Output:
%   label: 1 x N cluster label
%   model: trained model structure
%   llh: loglikelihood
% written by Mo Chen (sth4nth@gmail.com)
% from https://www.mathworks.com/matlabcentral/fileexchange/26184-em-algorithm-for-gaussian-mixture-model-em-gmm
% downloaded by Eli Bowen 5/24/2019 modified only for readability and print statements
function [label,model,llh] = MixGaussEm(X, K, maxIter, init)
    tol = 1e-6; % same as matlab's default
    llh = -inf(1, maxIter);
    R = initialization(X, K, init);
    
    for iter = 1 : maxIter
        [~,label(1,:)] = max(R, [], 2);
        
        if size(R, 2) - numel(unique(label)) > 0
            warning(['removing ',num2str(size(R, 2) - numel(unique(label))),' (of ',num2str(size(R, 2)),') clusters for having 0 members']);
        end
        R = R(:,unique(label)); % remove empty clusters

        tic();
        model = Maximization(X, R);
        time1 = toc();

        tic();
        [R,llh(iter)] = Expectation(X, model);
        time2 = toc();

        disp(['iter ',num2str(iter),' loglikelihood=',num2str(llh(iter)),' timing = ',num2str(time1),'s ',num2str(time2),'s']);

        if abs(llh(iter)-llh(iter-1)) < tol*abs(llh(iter))
            break;
        end
    end
    llh = llh(2:iter);
end
% from https://www.mathworks.com/matlabcentral/fileexchange/26184-em-algorithm-for-gaussian-mixture-model-em-gmm
% modified only to better match our kmeans and other methods of initializing
function [R] = initialization(X, K, init)
    N = size(X, 2);
    if isstruct(init) % init with a model
        assert(K == size(init.mu, 2));
        assert(~any(isnan(init.mu(:))) && ~any(isnan(init.sigma(:))) && ~any(isnan(init.w(:))), 'init better not contain NaN!');
        R = Expectation(X, init);
    elseif strcmp(init, 'random') || strcmp(init, 'sample') % sample is for compatability with matlab's built in kmeans
        label = ceil(K * rand(1, N));
        R = full(sparse(1:N, label, 1, N, K, N));
    elseif all(size(init)==[1,N])  % init with labels
        label = init;
        K = max(label);
        R = full(sparse(1:N, label, 1, N, K, N));
    else
        error('ERROR: init is not valid');
    end
end
% from https://www.mathworks.com/matlabcentral/fileexchange/26184-em-algorithm-for-gaussian-mixture-model-em-gmm
function [R,llh] = Expectation(X, model)
    mu = model.mu;
    sigma = model.sigma;
    w = model.w;
    N = size(X, 2);
    K = size(mu, 2);
    R = zeros(N, K);
    for i = 1:K
        R(:,i) = loggausspdf(X, mu(:,i), sigma(:,:,i));
    end
    R = bsxfun(@plus, R, log(w));
    T = logsumexp(R, 2);
    llh = sum(T) / N; % loglikelihood
    R = exp(bsxfun(@minus, R, T));
end
% from https://www.mathworks.com/matlabcentral/fileexchange/26184-em-algorithm-for-gaussian-mixture-model-em-gmm
function [model] = Maximization(X, R)
    [D,N] = size(X);
    K = size(R, 2);
    
    nk = sum(R, 1);
    w = nk / N;
    mu = bsxfun(@times, X*R, 1./nk);
    sigma = zeros(D, D, K);
    r = sqrt(R);
    for i = 1:K
        Xo = bsxfun(@minus, X, mu(:,i));
        Xo = bsxfun(@times, Xo, r(:,i)');
        sigma(:,:,i) = Xo*Xo'/nk(i) + eye(D)*(1e-6);
    end
    model.mu = mu;
    model.sigma = sigma;
    model.w = w;
end
