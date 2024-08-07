load("finalData.mat")

%reshape, cant handle images
data = reshape(data,[361,7368]);
my_data = reshape(my_data,[361,186]);

%add markers
data = [data;markers];
my_data = [my_data;my_markers];

%test on data
%test on my_data
num = floor(size(my_data,2)*0.75);
randIndices = randperm(size(my_data,2),size(my_data,2));
mix = [data, my_data(:,randIndices(1:num))];
test = my_data(:,randIndices(num+1:end));



load("finalData.mat")

mix = cat(3, data, my_data(:,:,randIndices(1:num)));
mixMarkers = cat(2,markers, my_markers(:,randIndices(1:num)));

test = my_data(:,:,randIndices(num+1:end));
testMarkers = my_markers(:,randIndices(num+1:end));

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

[a, netTrained, confusionFigure] = foldEvaluation(mix,mixMarkers, netStarter);
%%

a = reshape(test,[19,19,1,47]);
scores = minibatchpredict(netTrained,a);
classNames = {'rest', 'left' , 'right'};
YPred = scores2label(scores,classNames);
YTest = categorical(testMarkers, [1, 2, 3], classNames)';
accuracy = mean(YPred == YTest);
plotconfusion(YTest, YPred);
