function [accuracy, netTrained, confusionFigure] = foldEvaluation(data,labels, net)

% 0.75 train, 0.25 test
number_of_folds = 5;
classNames = {'rest', 'left' , 'right'};

folds = cvpartition(labels, 'KFold', number_of_folds);
accuracy_folds = zeros(number_of_folds, 1);

allPredictions = categorical([]);
allLabels = categorical([]);

for fold_index = 1:number_of_folds

    trainIdx = training(folds, fold_index);
    testIdx = test(folds, fold_index);

    XTest = reshape(data(:,:,testIdx), [19, 19, 1, sum(testIdx)]);
    XTrain = reshape(data(:,:,trainIdx), [19, 19, 1, sum(trainIdx)]);

    YTest = (categorical(labels(testIdx),[1 2 3], classNames))';
    YTrain = (categorical(labels(trainIdx),[1 2 3], classNames))';

    options = trainingOptions(...
    'sgdm', ... % stochastic gradient descent 'sgdm', 'adam'
    'Shuffle','every-epoch', ...  % Shuffle the training data before each training epoch, and shuffle the validation data before each network validation.
    ...%'InitialLearnRate',0.01, ... % The default value is 0.01 for the 'sgdm' solver and 0.001 for the 'rmsprop' and 'adam' solvers.
    'MaxEpochs',50, ...
    'ValidationData',{XTest, YTest}, ...
    'miniBatchSize', 50,... 
    'Verbose',false, ...
    'Plots','training-progress');

    
    %netTrained = trainnet(data,net,lossFcn,options)
    [netTrained,plot] = trainnet(XTrain,YTrain,net,"crossentropy",options);
    
    %Test
    scores = minibatchpredict(netTrained,XTest);
    YPred = scores2label(scores,classNames);
    accuracy_folds(fold_index,1) = mean(YPred == YTest);
    
    allPredictions = [allPredictions; YPred];
    allLabels = [allLabels; YTest];

    close(plot)
end

confusionFigure = plotconfusion(allLabels, allPredictions);

accuracy = mean(accuracy_folds);
    
end

