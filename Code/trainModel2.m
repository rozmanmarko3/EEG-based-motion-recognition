clear all;

name = 'MMDS data';
region = '13-20Hz';
epoch = '0s-4s';


%generate results folder
functionName = dbstack().name;
resultsFolder =['./results_',functionName];
mkdir(resultsFolder)
delete(fullfile(resultsFolder, '*'));

diaryFile = 'diary.txt';
dataMatrixName = 'finalData';

confusionPlotName = ['Confusion_',region,'_',epoch,'.png'];
netName = ['Net_',region,'_',epoch,'.mat'];

confusionPlotNameRetrained = ['Confusion_',region,'_',epoch,'_retrained','.png'];
netNameRetrained = ['Net_',region,'_',epoch,'_retrained','.mat'];

%clean results directory, initiate diary
delete(fullfile(resultsFolder, '*'));
edit(fullfile(resultsFolder, diaryFile))
diary(fullfile(resultsFolder, diaryFile))

%load data
%data -> MMDS data
%markers -> markers for MMDS data
%my_data -> my recordings
%my_markers -> markers for my recordings
load(dataMatrixName);

layers = [
    imageInputLayer([19,19,1])
    fullyConnectedLayer(100)
    leakyReluLayer %geluLayer %leakyReluLayer
    dropoutLayer(0.5)
    fullyConnectedLayer(10)
    geluLayer %leakyReluLayer
    dropoutLayer(0.5)
    fullyConnectedLayer(3)
    softmaxLayer
    ];

net = dlnetwork(layers);

classNames = {'rest', 'left' , 'right'};

folds = cvpartition(my_markers, 'Holdout', 0.2);


trainIdx = training(folds);
testIdx = test(folds);

XTest = reshape(data(:,:,testIdx), [19, 19, 1, sum(testIdx)]);
XTrain = reshape(data(:,:,trainIdx), [19, 19, 1, sum(trainIdx)]);

YTest = (categorical(my_markers(testIdx),[1 2 3], classNames))';
YTrain = (categorical(my_markers(trainIdx),[1 2 3], classNames))';

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

netRetrained = netTrained;

confusionFigure = plotconfusion(YTest, YPred);

save(fullfile(resultsFolder,netNameRetrained), 'netRetrained')

