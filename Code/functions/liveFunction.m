function result = liveFunction(dataChunk)
    persistent chunk_history eeg_filter iteration_number reorderIndex net
    %holds chunk history, persistant filters, iteration number...

    dataChunk = dataChunk(1:19,:);

    epoch_len = 4;
    low = 13;
    high = 30;
    filterOrder = 4;
    sampleRate = 500;
    num_of_channels = 19;
    historyLength = 5; %number of seconds saved in history
    
    %iteration counter
    if isempty(iteration_number)
        iteration_number = 1;
    else
        iteration_number = iteration_number + 1;
    end
    
    %initialize history on first pass
    if isempty(chunk_history)
        chunk_history = zeros(num_of_channels,sampleRate*historyLength);
    end
    
    %net
    if isempty(net)
        load("C:\Razno\EEG-based-motion-recognition\Code\results_trainModel\Net_13-20Hz_0s-4s_retrained.mat");
        net = netRetrained;
    end
    
    %load filter on first pass
    if  isempty(eeg_filter)
        
        Wn = [2*low/sampleRate, 2*high/sampleRate];
        
        [b, a] = butter(filterOrder, Wn, 'bandpass');
        
        eeg_filter = {b, a, zeros(max(length(a),length(b))-1,1)};
    
        %fvtool(eeg_filter{1},eeg_filter{2});
    end
    
    %generate reorder index
    if  isempty(reorderIndex)
    
        expectedOrder = {'C3','Cz','C4','Fp1','Fp2','F7','F3','Fz','F4','F8','T7','T8','P7','P3','Pz','P4','P8','O1','O2'};
        
        receivedOrder = {'F7', 'Fp1', 'Fp2', 'F8', 'F3', 'Fz', 'F4', 'C3', 'Cz', 'P8', 'P7', 'Pz', 'P4', 'T7', 'P3', 'O1', 'O2', 'C4', 'T8'};
    
        [~, reorderIndex] = ismember(expectedOrder, receivedOrder);
    end
    
    chunk_len = size(dataChunk,2);
    history_len = size(chunk_history,2);
    
    %add to back of history
    chunk_history = [chunk_history(:,chunk_len+1:history_len), dataChunk];
    
    %don't calculate untill you have enugh data for prediction model
    if epoch_len * sampleRate >  iteration_number * chunk_len
        result = 0;
        return
    end
    
    %get data needed for calculation from history
    chunk = chunk_history(:,history_len-(sampleRate*epoch_len)+1:history_len);
    
    [matrix,eeg_filter] = liveProcessing(chunk,reorderIndex,eeg_filter);

    scores = predict(net,reshape(matrix,19,19,1));
    result = scores2label(scores,{'Mirovanje','Leva','Desna'});
    
    %scores = trainedModel.predictFcn(reshape(matrix,361,1));
    %result = scores;
end

