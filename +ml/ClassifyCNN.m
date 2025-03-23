% Eli Bowen 3/2025
% INPUTS
%   trnData   - n_trn x n_features
%   trnLabel  - n_trn x 1
%   tstData   - n_tst x n_features
%   tstLabel  - n_tst x 1
%   n_classes - scalar int-valued numeric
%   n_trn_epochs_max
%   img_sz is [n_rows, n_cols, n_channels]
%   kernel_sz_in_layer = [3, 3, 3];
%   n_filters_in_layer = [8, 16, 32];
% RETURNS
%   acc
%   predLabel
function [acc, predLabel] = ClassifyCNN(trnData, trnLabel, tstData, tstLabel, n_classes, n_trn_epochs_max, img_sz, kernel_sz_in_layer, n_filters_in_layer)
    assert(size(trnData, 2) == size(tstData, 2));
    assert(size(trnData, 1) == numel(trnLabel));
    assert(size(tstData, 1) == numel(tstLabel));
    assert(numel(img_sz) == 3);
    assert(numel(kernel_sz_in_layer) == numel(n_filters_in_layer));
    
    initial_learning_rate = 0.01;
    pool_size = 2;
    pool_stride = 2;

    n_conv_layers = numel(kernel_sz_in_layer);

    % build the ordered list of layers
    layers = [imageInputLayer(img_sz)];
    for i = 1 : n_conv_layers
        layers(end+1) = convolution2dLayer(kernel_sz_in_layer(i), n_filters_in_layer(i), Padding="same");
        layers(end+1) = batchNormalizationLayer;
        layers(end+1) = reluLayer;

        if i < n_conv_layers % omit for last conv layer
            layers(end+1) = maxPooling2dLayer(pool_size, Stride=pool_stride);
        end
    end
    layers(end+1) = fullyConnectedLayer(n_classes);
    layers(end+1) = softmaxLayer;

    % reshape data for the CNN
    trnData = reshape(single(trnData), img_sz(1), img_sz(2), img_sz(3), []); % now n_rows x n_cols x n_channels x n_datapoints
    tstData = reshape(single(tstData), img_sz(1), img_sz(2), img_sz(3), []); % now n_rows x n_cols x n_channels x n_datapoints

    % train
    % set Plots="training-progress" to see a plot of loss
    options = trainingOptions("sgdm", MaxEpochs=n_trn_epochs_max, InitialLearnRate=initial_learning_rate, Shuffle="every-epoch", Plots="none", Metrics="accuracy", Verbose=false);
    net = trainnet(trnData, trnLabel(:), layers, "index-crossentropy", options);

    % classify the test data
    % To make predictions with multiple observations, use the minibatchpredict function. To convert the prediction scores to labels, use the scores2label function. The minibatchpredict function automatically uses a GPU if one is available. Otherwise, the function uses the CPU.
    scores = minibatchpredict(net, tstData);
    predLabel = double(scores2label(scores, categorical(1:n_classes)));
    
    % calculate the accuracy
    acc = sum(predLabel == tstLabel) / numel(tstLabel);
end