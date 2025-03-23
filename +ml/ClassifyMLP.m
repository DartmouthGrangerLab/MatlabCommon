% Eli Bowen 3/2025
% INPUTS
%   trnData   - n_trn x n_features
%   trnLabel  - n_trn x 1
%   tstData   - n_tst x n_features
%   tstLabel  - n_tst x 1
%   n_classes
%   n_trn_epochs_max
%   n_hidden_in_layer
% RETURNS
%   acc
%   predLabel
% n_hidden_in_layer e.g. [100, 100]
% data should be n_datapoints x n_features
function [acc, predLabel] = ClassifyMLP(trnData, trnLabel, tstData, tstLabel, n_classes, n_trn_epochs_max, n_hidden_in_layer)
    assert(size(trnData, 2) == size(tstData, 2));
    assert(size(trnData, 1) == numel(trnLabel));
    assert(size(tstData, 1) == numel(tstLabel));
    
    mini_batch_size = 128;

    n_features = size(trnData, 2);
    n_fully_connected_layers = numel(n_hidden_in_layer);

    % build the ordered list of layers
    layers = [featureInputLayer(n_features)];
    for i = 1 : n_fully_connected_layers
        layers(end+1) = fullyConnectedLayer(n_hidden_in_layer(i));
        layers(end+1) = reluLayer;
    end
    layers(end+1) = fullyConnectedLayer(n_classes);
    layers(end+1) = softmaxLayer;

    % train
    % set Plots="training-progress" to see a figure of the loss trajectory
    options = trainingOptions("adam", MaxEpochs=n_trn_epochs_max, MiniBatchSize=mini_batch_size, Shuffle="every-epoch", Plots="none", Metrics="accuracy", Verbose=false);
    net = trainnet(single(trnData), trnLabel(:), layers, "index-crossentropy", options);
    
    % classify the test data
    scores = minibatchpredict(net, single(tstData), MiniBatchSize=mini_batch_size);
    predLabel = double(scores2label(scores, categorical(1:n_classes)));

    % calculate the accuracy
    acc = sum(predLabel == tstLabel) / numel(tstLabel);
end
