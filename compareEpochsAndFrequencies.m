%variables
%tests CPCC for all combinations, GC for all time ranges
numberOfSubjects = 30;
frequencyBands = [0 4;4 8;8 13;13 20;20 40];
timeRanges =[0 1; 0 2; 2 4; 0 4];

baseUrl = 'C:\Users\rozma\Downloads\MMD\files\';

%generate results folder
functionName = dbstack().name;
resultsFolder =['./results_',functionName];
mkdir(resultsFolder)
delete(fullfile(resultsFolder, '*'));

resultsCPCC = zeros(size(frequencyBands,1),size(timeRanges,1));
resultsGC = zeros(1,size(timeRanges,1));

dataCPCC = cell(size(frequencyBands,1),size(timeRanges,1));
markersCPCC = cell(size(frequencyBands,1),size(timeRanges,1));
dataGC = cell(1,size(timeRanges,1));
markersGC = cell(1,size(timeRanges,1));

numberOfChannels = 19;
GCorder = 12;

delete(fullfile(resultsFolder, '*'));

frequencyLabels = cell(1,1);
for i = 1:size(frequencyBands,1)
    frequencyLabels{i} = sprintf('CPCC at %d-%d Hz', frequencyBands(i, 1), frequencyBands(i, 2));
end

timeLabels = cell(1,1);
for i = 1:size(timeRanges,1)
    timeLabels{i} = sprintf('%d-%d s', timeRanges(i, 1), timeRanges(i, 2));
end


%%
% genereate list of file names to process
locations = cell(numberOfSubjects*3,1);
counter = 1;
for fileNumber = 1:numberOfSubjects
    for run = [{'03'},{'07'},{'11'}]
        nameNumber = pad(string(fileNumber),3,'left','0');
        name = 'S' + nameNumber;
        seriesName = name + 'R'+run{1}+'.edf';
        location = baseUrl + name + '\' + seriesName;
        locations{counter} = location;
        counter = counter +1;
    end
end

locations = cellfun(@(c) c{1}, locations, 'UniformOutput', false);

%%
% using eeglab functions generate conectivity matrices with GC
for locIndx = 1:length(locations)

    EEG = pop_biosig(locations(locIndx));
    EEG = pop_select( EEG, 'channel',{'C3..','Cz..','C4..','Fp1.','Fp2.','F7..','F3..','Fz..','F4..','F8..','T7..','T8..','P7..','P3..','Pz..','P4..','P8..','O1..','O2..'});
    if(EEG.srate ~= 160)
        break
    end
    
    locutoff = 1;
    hicutoff = 45;
    EEG_filtered = pop_eegfiltnew(EEG, 'locutoff',locutoff,'hicutoff',hicutoff);

    for timeRangeIndx = 1:size(timeRanges,1)

        epochStart = timeRanges(timeRangeIndx,1);
        epochEnd = timeRanges(timeRangeIndx,2);
        EEG_Epoch = pop_epoch( EEG_filtered, {  }, [epochStart  epochEnd]);
        markers_all = [EEG_Epoch.urevent.edftype];

        counter = 1;
        data = zeros(numberOfChannels,numberOfChannels,size(EEG_Epoch.data,3));
        markers = zeros(1,size(EEG_Epoch.data,3));

        for chunkInx = 1:size(EEG_Epoch.data,3)
            dataChunk = EEG_Epoch.data(:,:,chunkInx);
    
            %rerefrence
            dataChunk = rereferenceChunk(dataChunk, n_chanels);
            
            %calculateGC
            conn = calculateGC(dataChunk, n_chanels, GCorder);
            
            %save
            data(:,:,counter) = conn;
            markers(counter) = markers_all(chunkInx);
            counter = counter+1;
        end

        dataGC{1,timeRangeIndx} = cat(3,dataGC{1,timeRangeIndx},data);
        markersGC{1,timeRangeIndx} = cat(2,markersGC{1,timeRangeIndx},markers);

        disp(['GC Trail: ', num2str(locIndx), '/', num2str(numberOfSubjects*3), ' time range: ', num2str(timeRangeIndx)])
    end
end



%%
% using eeglabs functions generate conectivity matrices with CPCC
for locIndx = 1:length(locations)

    EEG = pop_biosig(locations(locIndx));
    EEG = pop_select( EEG, 'channel',{'C3..','Cz..','C4..','Fp1.','Fp2.','F7..','F3..','Fz..','F4..','F8..','T7..','T8..','P7..','P3..','Pz..','P4..','P8..','O1..','O2..'});
    if(EEG.srate ~= 160)
        break
    end
    
    for frequencyBandIndx = 1:size(frequencyBands,1)

        locutoff = frequencyBands(frequencyBandIndx,1);
        hicutoff = frequencyBands(frequencyBandIndx,2);
        EEG_filtered = pop_eegfiltnew(EEG, 'locutoff',locutoff,'hicutoff',hicutoff);

        for timeRangeIndx = 1:size(timeRanges,1)

            epochStart = timeRanges(timeRangeIndx,1);
            epochEnd = timeRanges(timeRangeIndx,2);
            EEG_Epoch = pop_epoch( EEG_filtered, {  }, [epochStart  epochEnd]);
            markers_all = [EEG_Epoch.urevent.edftype];

            counter = 1;
            data = zeros(numberOfChannels,numberOfChannels,size(EEG_Epoch.data,3));
            markers = zeros(1,size(EEG_Epoch.data,3));

            for chunkInx = 1:size(EEG_Epoch.data,3)
                dataChunk = EEG_Epoch.data(:,:,chunkInx);
        
                %rerefrence
                dataChunk = rereferenceChunk(dataChunk, n_chanels);
                
                %hilbert and calculate CPCC 
                conn = calculateCPCC(dataChunk, n_chanels);
                
                %save
                data(:,:,counter) = conn;
                markers(counter) = markers_all(chunkInx);
                counter = counter+1;
            end

            dataCPCC{frequencyBandIndx,timeRangeIndx} = cat(3, dataCPCC{frequencyBandIndx,timeRangeIndx},data);
            markersCPCC{frequencyBandIndx,timeRangeIndx} = cat(2,markersCPCC{frequencyBandIndx,timeRangeIndx}, markers);

            disp(['Trail: ', num2str(locIndx), '/', num2str(numberOfSubjects*3) ,' frequency band: ', num2str(frequencyBandIndx),' time range: ', num2str(timeRangeIndx)])
        end
    end
end

%%
%downsample CPCC
for frequencyBandIndx = 1:size(frequencyBands,1) 
    for timeRangeIndx = 1:size(timeRanges,1)
        [dataCPCC{frequencyBandIndx,timeRangeIndx}, markersCPCC{frequencyBandIndx,timeRangeIndx}] = downSample(dataCPCC{frequencyBandIndx,timeRangeIndx}, markersCPCC{frequencyBandIndx,timeRangeIndx});
        disp('down')
    end
end
%downsample GC
for timeRangeIndx = 1:size(timeRanges,1)
    [dataGC{1,timeRangeIndx}, markersGC{1,timeRangeIndx}] = downSample(dataGC{1,timeRangeIndx}, markersGC{1,timeRangeIndx});
    disp('down')
end

%%
%train networks for CPCC
for frequencyBandIndx = 1:size(frequencyBands,1) 
    for timeRangeIndx = 1:size(timeRanges,1)

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

        data = dataCPCC{frequencyBandIndx,timeRangeIndx};
        markers = markersCPCC{frequencyBandIndx,timeRangeIndx};
        [accuracy, netTrained, confusionFigure] = foldEvaluation(data,markers, netStarter);
        
        saveas(confusionFigure,fullfile(resultsFolder,['Confusion ',frequencyLabels{frequencyBandIndx},' ', timeLabels{timeRangeIndx},'.png']))
        close(confusionFigure)
        resultsCPCC(frequencyBandIndx,timeRangeIndx) = accuracy;

    end
end

%%
%train networks for GC
for frequencyBandIndx = 1
    for timeRangeIndx = 1:size(timeRanges,1)

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

        data = dataGC{frequencyBandIndx,timeRangeIndx};
        markers = markersGC{frequencyBandIndx,timeRangeIndx};
        [accuracy, netTrained, confusionFigure] = foldEvaluation(data,markers, netStarter);
        
        saveas(confusionFigure,fullfile(resultsFolder,['Confusion GC ', timeLabels{timeRangeIndx},'.png']))
        close(confusionFigure)
        resultsGC(frequencyBandIndx,timeRangeIndx) = accuracy;

    end
end

%%
%plot
heatm = heatmap([resultsCPCC;resultsGC], 'XDisplayLabels', timeLabels, 'YDisplayLabels', [frequencyLabels,'GC']);
ylabel('Frequency bands');
xlabel('Epoch time ranges');
saveas(heatm,fullfile(resultsFolder,'Comparison.png'))