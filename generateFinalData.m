%% setup

% generateData iz MMDS in mojih posnetkov naredi podtatke za mrežo
% calculateCPCC naredi transformacijo in izračuna CPCC
% downSample odstrani naključne razrede, tako da je vseh enako
% isInRowForm preveri da so vrstice matrike kanali eegja
% liveFunction funkcija za prikazovanje klasifikacij v živo
% liveClasification sestavni del zgornje funkcije
% liveProcessing obdelava podatkov iz eegja
% rereferenceChunk odšteje povprečje stolpcev
% trainModel
% viusalizeData prikaže podatke v obliki matric

%program potrebuje okoli 5min

clear all;

low = 13;
high = 20;
epoch_time = 3;
desired_sampling_rate = 500;
filterOrder = 2;
n_chanels = 19;
numberOfSubjects = 109;

baseUrl = 'C:\Users\rozma\Downloads\MMD\files\';
mojPosnetekUrl = 'C:\Users\rozma\Downloads\MMD\mojPosnetek\skupaj.mat';

%filter setup
Wn = [2*low/desired_sampling_rate, 2*high/desired_sampling_rate];
[b, a] = butter(filterOrder, Wn, 'bandpass');
eeg_filter = {b, a, zeros(max(length(a),length(b))-1,1)};

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

locations = cellfun(@(c) c{1}, locations, 'UniformOutput', false);

%% procesiraj motor movment dataset
counter = 1;
for locIndx = 1:length(locations)

    %use eeglab to import, upsample to 500 and epoch
    EEG = pop_biosig(locations(locIndx));
    EEG = pop_select( EEG, 'channel',{'C3..','Cz..','C4..','Fp1.','Fp2.','F7..','F3..','Fz..','F4..','F8..','T7..','T8..','P7..','P3..','Pz..','P4..','P8..','O1..','O2..'});
    EEG = pop_resample( EEG, 500);

    %ali je to nespametno?
    filtered_chunk = filter(eeg_filter{1},eeg_filter{2},EEG.data');
    EEG.data = filtered_chunk';

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

%% procesiraj moj posnetek na primerljiv način

%podatkiStanjSkupaj => n*1 cell array posnetkov eventov
%stanjaSkupaj => n*1 double array indikatorjev stanj
load(mojPosnetekUrl)

my_data = zeros(19,19,1);
my_markers = stanjaSkupaj';

%reorder index
expectedOrder = {'C3','Cz','C4','Fp1','Fp2','F7','F3','Fz','F4','F8','T7','T8','P7','P3','Pz','P4','P8','O1','O2'};  
receivedOrder = {'F7', 'Fp1', 'Fp2', 'F8', 'F3', 'Fz', 'F4', 'C3', 'Cz', 'P8', 'P7', 'Pz', 'P4', 'T7', 'P3', 'O1', 'O2', 'C4', 'T8'};
[~, reorderIndex] = ismember(expectedOrder, receivedOrder);

%same filter, clean
eeg_filter = {b, a, zeros(max(length(a),length(b))-1,1)};


for i = 1:size(stanjaSkupaj,1)
    [my_data(:,:,i),eeg_filter] = liveProcessing(podatkiStanjSkupaj{i},reorderIndex,eeg_filter);
end

%remove matrices at the start of each recording, they are broken by the
%filter starting at 0
remove = [1,11,61,111,164,255];
my_data(:,:,remove) = [];
my_markers(remove) = [];

%% downsample and in prikaz


disp("Distribution of MMDS clases before downsampling")
groupcounts(markers')

disp("Distribution of clases of my recordings before downsampling")
groupcounts(my_markers')

%downsample and save
[data,markers] = downSample(data,markers);
[my_data,my_markers] = downSample(my_data,my_markers);
save("finalData",'data', 'markers', "my_markers", "my_data")

disp("Distribution of clases after downsampling")
groupcounts(markers')

disp("Distribution of clases of my recordings after downsampling")
groupcounts(my_markers')

disp("Done")
toc