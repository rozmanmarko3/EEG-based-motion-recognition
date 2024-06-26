%variables
numberOfSubjects = 30;
frequencyBands = [0.1 4;4 8;8 13;13 20;20 40];
timeRanges =[0 4];

baseUrl = 'C:\Users\rozma\Downloads\MMD\files\';



resultsEEGLAB = zeros(size(frequencyBands,1),size(timeRanges,1));
resultsMY = zeros(1,size(timeRanges,1));

dataEEGLAB = cell(size(frequencyBands,1),size(timeRanges,1));
markersEEGLAB = cell(size(frequencyBands,1),size(timeRanges,1));

dataMY = cell(size(frequencyBands,1),size(timeRanges,1));
markersMY = cell(size(frequencyBands,1),size(timeRanges,1));

numberOfChannels = 19;
GCorder = 12;

%generate results folder
functionName = dbstack().name;
resultsFolder =['./results_',functionName];
mkdir(resultsFolder)
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
% using eeglabs filter
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
                dataChunk = rereferenceChunk(dataChunk, numberOfChannels);
                
                %hilbert and calculate CPCC 
                conn = calculateCPCC(dataChunk, numberOfChannels);
                
                %save
                data(:,:,counter) = conn;
                markers(counter) = markers_all(chunkInx);
                counter = counter+1;
            end

            dataEEGLAB{frequencyBandIndx,timeRangeIndx} = cat(3, dataEEGLAB{frequencyBandIndx,timeRangeIndx},data);
            markersEEGLAB{frequencyBandIndx,timeRangeIndx} = cat(2,markersEEGLAB{frequencyBandIndx,timeRangeIndx}, markers);

            disp(['Trail: ', num2str(locIndx), '/', num2str(numberOfSubjects*3) ,' frequency band: ', num2str(frequencyBandIndx),' time range: ', num2str(timeRangeIndx)])
        end
    end
end

%% using my filter
for locIndx = 1:length(locations)
    
    for frequencyBandIndx = 1:size(frequencyBands,1)

        EEG = pop_biosig(locations(locIndx));
        
        EEG = pop_select( EEG, 'channel',{'C3..','Cz..','C4..','Fp1.','Fp2.','F7..','F3..','Fz..','F4..','F8..','T7..','T8..','P7..','P3..','Pz..','P4..','P8..','O1..','O2..'});
        if(EEG.srate ~= 160)
            break
        end

        locutoff = frequencyBands(frequencyBandIndx,1);
        hicutoff = frequencyBands(frequencyBandIndx,2);

        Wn = [2*locutoff/160, 2*hicutoff/160];
        [b, a] = butter(2, Wn, 'bandpass');
        eeg_filter = {b, a, zeros(max(length(a),length(b))-1,1)};
        filtered_chunk = filter(eeg_filter{1},eeg_filter{2},EEG.data');
        EEG.data = filtered_chunk';

        for timeRangeIndx = 1:size(timeRanges,1)

            epochStart = timeRanges(timeRangeIndx,1);
            epochEnd = timeRanges(timeRangeIndx,2);
            EEG_Epoch = pop_epoch( EEG, {  }, [epochStart  epochEnd]);
            markers_all = [EEG_Epoch.urevent.edftype];

            counter = 1;
            data = zeros(numberOfChannels,numberOfChannels,size(EEG_Epoch.data,3));
            markers = zeros(1,size(EEG_Epoch.data,3));

            for chunkInx = 1:size(EEG_Epoch.data,3)
                dataChunk = EEG_Epoch.data(:,:,chunkInx);
        
                %rerefrence
                dataChunk = rereferenceChunk(dataChunk, numberOfChannels);
                
                %hilbert and calculate CPCC 
                conn = calculateCPCC(dataChunk, numberOfChannels);
                
                %save
                data(:,:,counter) = conn;
                markers(counter) = markers_all(chunkInx);
                counter = counter+1;
            end

            dataMY{frequencyBandIndx,timeRangeIndx} = cat(3, dataMY{frequencyBandIndx,timeRangeIndx},data);
            markersMY{frequencyBandIndx,timeRangeIndx} = cat(2,markersMY{frequencyBandIndx,timeRangeIndx}, markers);

            disp(['Trail: ', num2str(locIndx), '/', num2str(numberOfSubjects*3) ,' frequency band: ', num2str(frequencyBandIndx),' time range: ', num2str(timeRangeIndx)])
        end
    end
end

%%
%downsample EEGLAB
for frequencyBandIndx = 1:size(frequencyBands,1) 
    for timeRangeIndx = 1:size(timeRanges,1)
        [dataEEGLAB{frequencyBandIndx,timeRangeIndx}, markersEEGLAB{frequencyBandIndx,timeRangeIndx}] = downSample(dataEEGLAB{frequencyBandIndx,timeRangeIndx}, markersEEGLAB{frequencyBandIndx,timeRangeIndx});
        disp('down')
    end
end
%downsample MY
for timeRangeIndx = 1:size(timeRanges,1)
    [dataMY{1,timeRangeIndx}, markersMY{1,timeRangeIndx}] = downSample(dataMY{1,timeRangeIndx}, markersMY{1,timeRangeIndx});
    disp('down')
end

%%
%train networks for EEGLAB
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

        data = dataEEGLAB{frequencyBandIndx,timeRangeIndx};
        markers = markersEEGLAB{frequencyBandIndx,timeRangeIndx};
        [accuracy, netTrained, confusionFigure] = foldEvaluation(data,markers, netStarter);
        
        saveas(confusionFigure,fullfile(resultsFolder,['Confusion eeglab',frequencyLabels{frequencyBandIndx},' ', timeLabels{timeRangeIndx},'.png']))
        close(confusionFigure)
        resultsEEGLAB(frequencyBandIndx,timeRangeIndx) = accuracy;

    end
end

%%
%train networks for MY
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

        data = dataMY{frequencyBandIndx,timeRangeIndx};
        markers = markersMY{frequencyBandIndx,timeRangeIndx};
        [accuracy, netTrained, confusionFigure] = foldEvaluation(data,markers, netStarter);
        
        saveas(confusionFigure,fullfile(resultsFolder,['Confusion my ', frequencyLabels{frequencyBandIndx},'.png']))
        close(confusionFigure)
        resultsMY(frequencyBandIndx,timeRangeIndx) = accuracy;

    end
end

%%
%plot
heatm = heatmap(resultsEEGLAB-resultsMY, 'XDisplayLabels', timeLabels, 'YDisplayLabels', frequencyLabels);
ylabel('Frequency bands');
xlabel('Epoch time ranges');
saveas(heatm,fullfile(resultsFolder,'Comparison.png'))