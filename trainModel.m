clear all;

name = 'MMDS data';
region = 'full GC and 13-20Hz CPCC';
epoch = '0s-4s';

resultsDirectory = './results';
diaryFile = 'diary.txt';
dataMatrixName = 'finalData';

confusionPlotName = ['Confusion_',region,'_',epoch,'.png'];
netName = ['Net_',region,'_',epoch,'.mat'];

confusionPlotNameRetrained = ['Confusion_',region,'_',epoch,'_retrained','.png'];
netNameRetrained = ['Net_',region,'_',epoch,'_retrained','.mat'];

%clean results directory, initiate diary
delete(fullfile(resultsDirectory, '*'));
edit(fullfile(resultsDirectory, diaryFile))
diary(fullfile(resultsDirectory, diaryFile))

%load data
%data -> MMDS data
%markers -> markers for MMDS data
load(dataMatrixName);

layers = [
    imageInputLayer([19,19,2])
    fullyConnectedLayer(100)
    leakyReluLayer %geluLayer %leakyReluLayer
    dropoutLayer(0.5)
    fullyConnectedLayer(10)
    geluLayer %leakyReluLayer
    dropoutLayer(0.5)
    fullyConnectedLayer(3)
    softmaxLayer
    ];

netStarter = dlnetwork(layers);

[accuracy, netTrained, confusionFigure ] = foldEvaluation(data,markers,netStarter);

saveas(confusionFigure, fullfile(resultsDirectory,confusionPlotName))
save(fullfile(resultsDirectory,netName), 'netTrained')

print('done')

