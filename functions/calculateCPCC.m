function conectivityMatrix = calculateCPCC(chunk,n_chanels)
    
    %check if it is in proper form
    isInRowForm(chunk,n_chanels);

    %hilbert transform
    hil = hilbert(chunk');
    
    
    conn = zeros(n_chanels, n_chanels);
    %CPCC
    for c1 = 1:n_chanels
        for c2 = c1+1:n_chanels
            %channels
            channel_c1 = hil(:,c1);
            channel_c2 = hil(:,c2);
            
            % Calculate CPCC
            CPCC = corr(channel_c1(:), channel_c2(:));
            conn(c1, c2) = real(CPCC);
            conn(c2, c1) = imag(CPCC);
        end
    end

    conectivityMatrix = conn;
end

