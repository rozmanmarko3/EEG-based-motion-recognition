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

netStarter = dlnetwork(layers);

[accuracy, netTrained, confusionFigure ] = foldEvaluation(data,markers,netStarter);

saveas(confusionFigure, fullfile(resultsFolder,confusionPlotName))
save(fullfile(resultsFolder,netName), 'netTrained')

%additionaly train on my data
[accuracy, netRetrained, confusionFigure ] = foldEvaluation(my_data,my_markers,netTrained);

saveas(confusionFigure, fullfile(resultsFolder,confusionPlotNameRetrained))
save(fullfile(resultsFolder,netNameRetrained), 'netRetrained')

print('done')

