function out = isInRowForm(chunk,numOfChannels)
    if size(chunk,1) == numOfChannels
        out = 1;
    else
        error("data chunks rows must be the electrode signals")
    end
end

