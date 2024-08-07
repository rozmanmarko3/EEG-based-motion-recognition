function [accuracy, netTrained, confusionFigure] = trainNetwork(data,labels, net)

classNames = {'rest', 'left' , 'right'};

folds = cvpartition(labels, 'HoldOut', 0.2);

    trainIdx = training(folds);
    testIdx = test(folds);

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
    'Verbose',true, ...
    'Plots','none');

    
    %netTrained = trainnet(data,net,lossFcn,options)
    [netTrained,plot] = trainnet(XTrain,YTrain,net,"crossentropy",options);
    
    %Test
    scores = minibatchpredict(netTrained,XTest);
    YPred = scores2label(scores,classNames);
    accuracy = mean(YPred == YTest);
   

confusionFigure = plotconfusion(YPred, YTest);

    
end

