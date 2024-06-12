function [matrix,eeg_filter] = liveProcessing(dataChunk,reorderIndex, eeg_filter)
    %proceses chunk, returns the matrix and new filter

    %cut unneded channels
    dataChunk = dataChunk(1:19,:);
    
    %reorder
    chunk = dataChunk(reorderIndex, :);
    
    %filter
    [chunk, newState] = filter(eeg_filter{1},eeg_filter{2},chunk',eeg_filter{3});
    eeg_filter{3} = newState;
    chunk = chunk';

    %cut only 4s
    chunk = chunk(:,1:2000);

    %rerefrence
    chunk = rereferenceChunk(chunk,19);
    
    %hilbert transform and cpcc
    matrix = calculateCPCC(chunk,19);

end

