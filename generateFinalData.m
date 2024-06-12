%% setup

clear all;

low = 13;
high = 20;
epoch_time = 4;

n_chanels = 19;
numberOfSubjects = 50;

baseUrl = 'C:\Users\rozma\Downloads\MMD\files\';
mojPosnetekUrl = 'C:\Users\rozma\Downloads\MMD\mojPosnetek\skupaj.mat';

%time
tic

%genereate list of file names to process
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

%data
data = zeros(19,19,1);
markers = zeros(1);

%data
data2 = zeros(19,19,1);

locations = cellfun(@(c) c{1}, locations, 'UniformOutput', false);

%% procesiraj motor movment dataset CPCC 13-20
counter = 1;
for locIndx = 1:length(locations)

    %use eeglab to import, upsample to 500 and epoch
    EEG = pop_biosig(locations(locIndx));
    EEG = pop_select( EEG, 'channel',{'C3..','Cz..','C4..','Fp1.','Fp2.','F7..','F3..','Fz..','F4..','F8..','T7..','T8..','P7..','P3..','Pz..','P4..','P8..','O1..','O2..'});
    EEG = pop_resample( EEG, 500);
    EEG = pop_eegfiltnew(EEG, 'locutoff',low,'hicutoff',high);
    filtered_chunk = EEG.data;

    if any(isnan(filtered_chunk), 'all') || any(isinf(filtered_chunk), 'all')
        error('Filtered data contains NaNs or Infs');
    end

    
    EEG_Epoch = pop_epoch( EEG, {  }, [0  epoch_time], 'newname', 'EDF file epochs');
    markers_all = [EEG_Epoch.urevent.edftype];

    disp(locations(locIndx))

    for chunkInx = 1:size(EEG_Epoch.data,3)
        dataChunk = EEG_Epoch.data(:,:,chunkInx);
            
        %filter ???
        % Filter tukaj vendar epohe med sabo niso povezane. Trajajo točno 4s
        % med eventi je tudi po 4.5s? Eeg lab vrjetno zavrže 0.5s?
        % Stanje filtra tukaj vrjetno tudi nima smisla med posnetki različnih ljudi?
        % če uporabim eeglab filter, bo potem drugače kot pri
        % klasifikaciji v real time, saj faze ne bodo zamaknjene.
        % Bi bila rešitev filriranje celote s tem filtorm brez stanja, tam okoli vrstice 46?
        %filtered_chunk = filter(eeg_filter{1},eeg_filter{2},dataChunk');
        %filtered_chunk = filtered_chunk';

        %rerefrence
        dataChunk = rereferenceChunk(dataChunk, n_chanels);
        
        %hilbert and calculate CPCC 
        conn = calculateCPCC(dataChunk, n_chanels);
        
        %save
        data(:,:,counter) = conn;
        markers(counter) = markers_all(chunkInx);
        counter = counter+1;
    end
end


%% procesiraj motor movment dataset CPCC 0.5-4
low = 0.5;
high = 4;

counter = 1;
for locIndx = 1:length(locations)

    %use eeglab to import, upsample to 500 and epoch
    EEG = pop_biosig(locations(locIndx));
    EEG = pop_select( EEG, 'channel',{'C3..','Cz..','C4..','Fp1.','Fp2.','F7..','F3..','Fz..','F4..','F8..','T7..','T8..','P7..','P3..','Pz..','P4..','P8..','O1..','O2..'});
    EEG = pop_resample( EEG, 500);
    EEG = pop_eegfiltnew(EEG, 'locutoff',low,'hicutoff',high);
    filtered_chunk = EEG.data;

    if any(isnan(filtered_chunk), 'all') || any(isinf(filtered_chunk), 'all')
        error('Filtered data contains NaNs or Infs');
    end

    
    EEG_Epoch = pop_epoch( EEG, {  }, [0  epoch_time], 'newname', 'EDF file epochs');
    markers_all = [EEG_Epoch.urevent.edftype];

    disp(locations(locIndx))

    for chunkInx = 1:size(EEG_Epoch.data,3)
        dataChunk = EEG_Epoch.data(:,:,chunkInx);
            
        %filter ???
        % Filter tukaj vendar epohe med sabo niso povezane. Trajajo točno 4s
        % med eventi je tudi po 4.5s? Eeg lab vrjetno zavrže 0.5s?
        % Stanje filtra tukaj vrjetno tudi nima smisla med posnetki različnih ljudi?
        % če uporabim eeglab filter, bo potem drugače kot pri
        % klasifikaciji v real time, saj faze ne bodo zamaknjene.
        % Bi bila rešitev filriranje celote s tem filtorm brez stanja, tam okoli vrstice 46?
        %filtered_chunk = filter(eeg_filter{1},eeg_filter{2},dataChunk');
        %filtered_chunk = filtered_chunk';

        %rerefrence
        dataChunk = rereferenceChunk(dataChunk, n_chanels);
        
        %hilbert and calculate CPCC 
        conn = calculateCPCC(dataChunk, n_chanels);
        
        %save
        data2(:,:,counter) = conn;
        counter = counter+1;
    end
end

%% combine data

data = reshape(data, [19, 19, 1, size(data,3)]);
data2 = reshape(data2, [19, 19, 1, size(data2,3)]);
data = cat(3,data,data2);

%% downsample and in prikaz

%downsample and save
[data,markers] = downSample(data,markers);
save("finalData",'data', 'markers')

disp("Distribution of clases after downsampling")
groupcounts(markers')

disp("Done")
toc