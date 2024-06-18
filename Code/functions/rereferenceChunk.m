function chunk = rereferenceChunk(chunk,numOfChannels)
    
    %check if it is in proper form
    isInRowForm(chunk,numOfChannels);

    %calculate
    column_means = mean(chunk);
    subtract = column_means .* ones(size(chunk, 1), 1);
    chunk = chunk - subtract;
    
end

