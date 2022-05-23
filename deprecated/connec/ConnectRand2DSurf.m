% Eli Bowen 1/14/2020
% given some set or population (e.g. of neurons), forms connections amonst them
% INPUTS:
%   srcMsk  - 1 x n (logical) mask on nrnlst (neurons which will project)
%   dstMsk  - 1 x n (logical) mask on nrnlst (the destination neuron list)
%   posR    - 1 x n (numeric)
%   posC    - 1 x n (numeric)
%   percent - % of random synapses per input, per output, or both
%   sigma   - gaussian sigma (in same units as connec.posX, posY)
%   method  - (char) 'srcchoose', 'dstchoose', or 'hypergeom'
%   pdfMode - (char) 'gauss' = gaussian func of dist, ___
% RETURNS:
%   src2HitIdx - index into the population (numbers 1 --> n)
%   dst2HitIdx - index into the population (numbers 1 --> n)
function [src2HitIdx,dst2HitIdx] = ConnectRand2DSurf(srcMsk, dstMsk, posR, posC, percent, sigma, method, pdfMode)
    validateattributes(srcMsk,  {'logical'}, {'vector'});
    validateattributes(dstMsk,  {'logical'}, {'vector'});
    validateattributes(posR,    {'numeric'}, {'vector'});
    validateattributes(posC,    {'numeric'}, {'vector'});
    validateattributes(percent, {'double'},  {'nonempty','scalar','positive'});
    validateattributes(sigma,   {'double'},  {'nonempty','scalar','positive'});
    validateattributes(method,  {'char'},    {'nonempty','vector'});
    validateattributes(pdfMode, {'char'},    {'nonempty','vector'});
    assert(numel(srcMsk) == numel(dstMsk) && numel(srcMsk) == numel(posR) && numel(srcMsk) == numel(posC));
    assert(any(srcMsk) && any(dstMsk));
    srcMsk = srcMsk(:)'; % so we can assume it's 1 x n not n x 1
    dstMsk = dstMsk(:)'; % so we can assume it's 1 x n not n x 1

    srcIdx = find(srcMsk);
    dstIdx = find(dstMsk);
    n_src = numel(srcIdx);
    n_dst = numel(dstIdx);
    n_per_src = round(percent * sum(dstMsk));
    n_new_syn = n_per_src * n_src;
    n_per_dst = ceil(n_new_syn / n_dst); % NOT often a whole number (must err on the high side or we'll run out of destination synapses before we've given every neuron n_per_src)

    % compute pairwise dists from each source (gauss center) to each destination
    dists = pdist2([posR(srcMsk)',posC(srcMsk)'], [posR(dstMsk)',posC(dstMsk)'], 'euclidean'); % n_src x n_dst

    % compute gaussian func of said dists
    if strcmp(pdfMode, 'gauss')
        pdf = normpdf(dists, 0, sigma); % n_src x n_dst
    else
        error('unknown pdfMode');
    end

    if strcmp(method, 'srcchoose')
        src2HitIdx = zeros(n_per_src, n_src);
        dst2HitIdx = zeros(n_per_src, n_src);
%         src2HitIdx = ones(n_per_src, n_src) .* srcIdx(:)'; % implicit expansion, verified same as below (but not much faster)
        for i = 1 : n_src
            src2HitIdx(:,i) = srcIdx(i);
            dst2HitIdx(:,i) = datasample(dstIdx, n_per_src, 'Replace', false, 'Weights', pdf(i,:)); % sample the pdf
%             dst2HitIdx(:,i) = randsample(dstIdx, n_per_src, true, pdf(i,:)); % sample the pdf
        end
    elseif strcmp(method, 'dstchoose')
        src2HitIdx = zeros(n_per_dst, n_dst);
        dst2HitIdx = zeros(n_per_dst, n_dst);
%         dst2HitIdx = ones(n_per_dst, n_dst) .* dstIdx(:)'; % implicit expansion, verified same as below (but not much faster)
        for i = 1 : n_dst % 1 s for 1 million synapses
            src2HitIdx(:,i) = datasample(srcIdx, n_per_dst, 'Replace', false, 'Weights', pdf(:,i)); % sample the pdf
            dst2HitIdx(:,i) = dstIdx(i);
        end
    elseif strcmp(method, 'hypergeom')
        error('Im not respecting srcIdx and dstIdx');
        % transpose so that src is the 2nd index (for speed below)
        dists = dists';
        pdf = pdf';
        
        %% this is a tricky algorithm problem
        % solution 1:
        % put each neuron up for auction n_per_dst times
        % each time, source neurons bid by sampling from their gaussian pdf, or bid 0 if they've reached n_per_src
        % problem: last source neurons left bidding may not be able to achieve a gaussian - distribution may have non-gaussian kurtosis
        % solution 2:
        % run ConnectRandNHypergeometric()
        % then keep swapping pairs of destinations within each source until the spatial distribution is gaussian
        % problem: starting from uniform connectivity, local gaussian connectivity means almost every synapse will get swapped
        % solution 3:
        % run ConnectRandGaussProb2DSurfNPerSrc()
        % then swap pairs of destinations within each source so we get equal n_per_dst
        % problem: we need to preserve the gauss as we swap, which means choosing each swap is a multiple optimization problem
        % solution 4:
        % like biology, n_per_src rounds, each source neuron makes one synapse per round sampling from their distribution
        % as you go further from the neuron, it's competing with more neurons (outside parts of its distribution overlap with more distributions)
        % so the sampling distribution of source i d_i(x,y) can't be gaussian,
        % ^ it's the solution of g(x,y) = d_i(x,y) - sumforalljnotequaltoi(d_j(x,y))
        % ^ or it would be, if you could sample with replacement

        % also need to detect situations where the gaussian is too small (n_per_src means connecting to all the neurons within the gaussian, so a non-gaussian distribution)
        % I like solution 2 for the above need - as we go about swapping, we can detect we're running out of options

        % trying a 1D simulation of solution 4:
%         sigma = 250; % there are 2000 destination neurons within this region
%         srcPosR = 0:0.01:500;
%         srcPosC = zeros(size(srcPosR));
%         dstPosR = 0:0.02:500;
%         dstPosC = zeros(size(dstPosR));
%         n_src = numel(srcPosR);
%         n_dst = numel(dstPosR);
%         n_per_src = round(n_src * 0.2);
%         n_new_syn = n_per_src * n_src;
%         n_per_dst = ceil(n_per_src * n_src / n_dst); % NOT often a whole number (must err on the high side or we'll run out of destination synapses before we've given every neuron n_per_src)
    
        %% sample the pdf
        %NEWEST WAY
        % 1. find the unit distance of the grid
        % assumes that destinations are arranged in a consistent grid
        %TODO
        % find the circle radius whose area contains n_per_src destination neurons
        %TODO
        % connect n_per_src
    
        %NEW WAY
        %TODO!!!: sample from the list of available destination synapses (not neurons)
%         n_per_dst = floor(n_per_src * n_src / n_dst); % NOT often a whole number (must err on the high side or we'll run out of destination synapses before we've given every neuron n_per_src)
        syn_dstNrns = ones(n_per_dst, n_dst) .* (1:n_dst); % implicit expansion
        syn_dstNrns = [syn_dstNrns(:)',randperm(numel(syn_dstNrns), n_new_syn-numel(syn_dstNrns))]; % add a few more unevenly to reach n_new_syn
        % measure dist and compute PDF between source neurons/axons and destination neuron synapses 
        pdf2 = zeros(numel(syn_dstNrns), n_src); % lots of RAM (n_new_syn x n_src)
        for i = 1 : n_src
            pdf2(:,i) = pdf(syn_dstNrns,i);
        end
        % now sample from the total list of pdfs, remove duplicates, and repeat until all items are accounted for
        oneToNSrc = 1:n_src; % stored for efficiency
        currCountPerSrc = zeros(1, n_src); % number of synapses already formed for each source
        uniqueSyn_src = [];
        uniqueSyn_dst = [];
        uniqueSynID   = [];
        count = 1;
        while numel(uniqueSynID) < n_new_syn
            t = tic();
            tempSrc = ones(n_per_src, n_src) .* oneToNSrc;
            tempDst = zeros(n_per_src, n_src);
            tempSynID = zeros(n_per_src, n_src);
            for i = 1 : n_src % 291 s
                if currCountPerSrc(i) ~= n_per_src
                    [tempDst(:,i),tempSynID(:,i)] = datasample(syn_dstNrns, n_per_src, 'Replace', false, 'Weights', pdf2(:,i));
                end
            end
            tempSrc(:,currCountPerSrc==n_per_src)   = [];
            tempDst(:,currCountPerSrc==n_per_src)   = [];
            tempSynID(:,currCountPerSrc==n_per_src) = [];

            %TODO: remove duplicate synapses (same src and dst via different synid)

            % shuffle new synapses s.t. duplicates will be removed randomly in call to unique() (but only new synapses will be removed)
            perm = randperm(numel(tempSynID));
            prvNUniqueSyn = numel(uniqueSynID);
            uniqueSyn_src = [uniqueSyn_src,tempSrc(perm)];
            uniqueSyn_dst = [uniqueSyn_dst,tempDst(perm)];
            uniqueSynID = [uniqueSynID,tempSynID(perm)];

            % eliminate duplicate synapses from the end of the list
            [uniqueSynID,idx] = unique(uniqueSynID, 'stable');
            uniqueSyn_src = uniqueSyn_src(idx);
            uniqueSyn_dst = uniqueSyn_dst(idx);

            newSynMsk = (idx > prvNUniqueSyn);
            newUniqueSyn_src = uniqueSyn_src(newSynMsk);
            newUniqueSyn_dst = uniqueSyn_dst(newSynMsk);
            newUniqueSynID = uniqueSynID(newSynMsk);

            % make sure we get equal N per src (AFTER deleting duplicates)
            minCount = NaN;
            if sum(newSynMsk) > 0 && max(currCountPerSrc) < n_per_src - 1 % if we aren't approaching the conclusion of innervation
                newSrcSynCount = CountNumericOccurrences(newUniqueSyn_src, oneToNSrc);
                minCount = min(newSrcSynCount(newSrcSynCount~=0));
                keep = false(size(newUniqueSyn_src));
                for i = 1 : n_src
                    isI = find(newUniqueSyn_src == i);
                    if numel(isI) ~= 0
                        keep(isI(1:minCount)) = true;
                    end
                end
                uniqueSyn_src = [uniqueSyn_src(~newSynMsk),newUniqueSyn_src(keep)];
                uniqueSyn_dst = [uniqueSyn_dst(~newSynMsk),newUniqueSyn_dst(keep)];
                uniqueSynID = [uniqueSynID(~newSynMsk),newUniqueSynID(keep)];
            end

            %TODO: now "disable" any sources or destinations that are fully assigned
            currCountPerSrc = CountNumericOccurrences(uniqueSyn_src, oneToNSrc);
            %PROBLEM: currCountPerSrc never reaches nPerSyn for anyone until it's reached for everyone

            disp('--');
            toc(t)
            disp(count);
            disp(minCount);
            disp([num2str(numel(uniqueSynID)),' of ',num2str(n_new_syn)]);
            count = count + 1;
        end
        src2HitIdx = uniqueSyn_src;
        dst2HitIdx = uniqueSyn_dst;
        error('validate');
    
%         uniqueSelections = [];
%         src2HitIdx = [];
%         dst2HitIdx = [];
%         while numel(uniqueSelections) < n_new_syn
%             [y,idx] = datasample(data, k, dim, 'Replace', false, 'Weights', w);
%             samp = randsample(n_new_syn*n_src, n_new_syn, true, pdf2(:));
%             [syn_dstIdx,srcIdx] = ind2sub(size(pdf2), samp);
%             uniqueSelections = unique([uniqueSelections;samp], 'stable'); % eliminates duplicates
%             %TODO: we're sampling from the list of all possible assignments of src axons to dst synapses
%             %^unique should mean unique dst synapses, regardless of which source got assigned
%         end
%         %TODO: uniqueSelections must be translated from pdf2 indices to src/dst neuron indices
%         dst2HitIdx = syn_dstNrns(uniqueSelections);
%         src2HitIdx = ones(n_per_src, n_src) .* (1:n_src); % implicit expansion
%         src2HitIdx = src2HitIdx(:)';
%         src2HitIdx = src2HitIdx(uniqueSelections);
    
        % first sample too many
%         n_per_dst = ceil(n_per_src * n_src / n_dst); % NOT often a whole number (must err on the high side or we'll run out of destination synapses before we've given every neuron n_per_src)
%         n2Oversample = n_per_src * 2;
%         selections = zeros(n2Oversample, n_src);
%         parfor i = 1:n_src % takes just a few secs with the parfor
%             uniqueSelections = [];
%             while numel(uniqueSelections) < n2Oversample
%                 %TODO: use datasample instead!
%                 uniqueSelections = unique([uniqueSelections;randsample(n_dst, n2Oversample, true, pdf(:,i))], 'stable'); % eliminates duplicates
%             end
%             selections(:,i) = uniqueSelections(1:n2Oversample);
%         end
%     %     nUnique = zeros(1, n_src); % number of unique destination neurons synapsed per source
%     % %     for i = 1:n_src % 335 s without the parfor
%     % %         uniqueSelections = unique(randsample(n_dst, size(selections, 1), true, pdf(:,i)), 'stable'); % eliminates duplicates
%     % %         nUnique(i) = numel(uniqueSelections);
%     % %         selections(1:nUnique(i),i) = uniqueSelections;
%     % % %         while numel(uniqueSelections) < n_dst
%     % % %             %TODO: use datasample instead!
%     % % %             selections(:,i) = [uniqueSelections;randsample(n_dst, n_dst-numel(uniqueSelections), true, pdf(:,i))];
%     % % %             uniqueSelections = unique(selections(:,i));
%     % % %         end
%     % %     end
%     %     parfor i = 1:n_src % 60 s with the parfor
%     %         %TODO: use datasample instead!
%     %         uniqueSelections = unique(randsample(n_dst, n2Oversample, true, pdf(:,i)), 'stable'); % eliminates duplicates
%     %         nUnique(i) = numel(uniqueSelections);
%     %         selections(:,i) = [uniqueSelections;NaN(n2Oversample-nUnique(i), 1)];
%     %     end
%     %     assert(min(nUnique) > n_per_src); % if you fail this, increase n2Oversample
%     %     selections(min(nUnique)+1:end,:) = []; % shrink size a bit for performance (there are still NaNs)
%         % then remove the excess (uniformly, to preserve the gaussian shape)
%         uniqueVals = 1:n_dst; % for efficiency
%         t=tic();
%         while size(selections, 1) > n_per_src
%             dstSynCount = CountNumericOccurrences(selections(:), uniqueVals); % 20 s
%             assert(min(dstSynCount) > n_per_dst)
%     %         figure;bar(dstSynCount);figure;histogram(dstSynCount);
%             selection_dstSynCount = dstSynCount(selections); % 8 s
% 
%             [~,idx] = max(selection_dstSynCount+rand(size(selection_dstSynCount))./10, [], 1); % makes sure we use random tie breaks
%             % swap last item with max item
%             temp = selections(end,:);
%             for i = 1:n_src % 14 s
%                 selections(end,i) = selections(idx(i),i);
%                 selections(idx(i),i) = temp(i);
%             end
%             % below is slower
%     %         [~,idx] = sort(selection_dstSynCount, 1, 'ascend'); % 19 s % sort each col (src) by dstSynCount (nans at the end)
%     %         for i = 1:n_src % 14 s
%     %              selections(:,i) = selections(idx(:,i),i);
%     %         end
% 
%             selections(end,:) = []; % delete the last row, re-count, repeat
%         end
%         toc(t)
%         % convert to output format
%         src2HitIdx = ones(n_per_src, n_src) .* (1:n_src); % implicit expansion
%         src2HitIdx = src2HitIdx(:)';
%         dst2HitIdx = selections(:)';
% 
%         figure;histogram(dst2HitIdx(mask)-src2HitIdx(mask));
    
        % another way (incomplete)
%         n_per_dst = ceil(n_per_src * n_src / n_dst); % NOT often a whole number (must err on the high side or we'll run out of destination synapses before we've given every neuron n_per_src)
%     %     n_dstRemaining = n_per_dst .* ones(n_dst, 1);
%         dists = (dists < sigma); % compute radial basis function, then threshold
%         possibleConnectionsPerSrc = sum(dists, 1); % src is on 2nd dim; sum along 1st
%         possibleConnectionsPerDst = sum(dists, 2); % dst is on 1st dim; sum along 2nd
%         assert(all(possibleConnectionsPerSrc > n_per_src) && all(possibleConnectionsPerDst > n_per_dst));
% 
%         isConnected = false(n_dst, n_src); % ordered so that src is the 2nd index (for speed below)
%         selec = rand(n_src, n_per_src); % fraction of the way through the possibleSelections list to find a value
%         t = tic();
%         for i = 1:n_per_src
%             temp = dists & ~isConnected;
%             for j = 1:n_src
%                 possibleSelections = find(temp(:,j) & n_dstRemaining > 0);
%                 if ~isempty(possibleSelections) % near the end, especially around the edges, we some neurons will run out of options
%                     selection = possibleSelections(ceil(selec(j,i) * numel(possibleSelections)));
%     %                 selection = possibleSelections(randi(numel(possibleSelections)));
%     %                 selection = srcPos(j) + randi(2*hatFuncRadius + 1) - (hatFuncRadius+1);
%     %                 if selection > 0 && selection < n_dst && n_srcRemaining(j) > 0 && n_dstRemaining(selection) > 0 && ~any(dst2HitIdx(src2HitIdx==j) == selection)
%                     isConnected(selection,j) = true;
%                     n_dstRemaining(selection) = n_dstRemaining(selection) - 1;
%                 end
%             end
%             disp([num2str(i / n_per_src * 100),'%, ',num2str(toc(t)),' s elapsed']);
%         end
%         src2HitIdx = ones(n_src, n_per_src) .* (1:n_src)'; % implicit expansion
%         dst2HitIdx = zeros(n_src, n_per_src);
%         for j = 1:n_src
%             dst2HitIdx(j,:) = find(isConnected(:,j)');
%         end
%         src2HitIdx = src2HitIdx(:)';
%         dst2HitIdx = dst2HitIdx(:)';
%         mask = (src2HitIdx >= 2*sigma & src2HitIdx <= n_src-2*sigma);
    else
        error('unknown method');
    end

    src2HitIdx = src2HitIdx(:)';
    dst2HitIdx = dst2HitIdx(:)';
end