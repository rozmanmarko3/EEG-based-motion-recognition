function conectivityMatrix = calculateGC(chunk,n_chanels, order)
    
    %check if it is in proper form
    isInRowForm(chunk,n_chanels);
    
    conn = zeros(n_chanels, n_chanels);
    %GC
    for c1 = 1:n_chanels
        for c2 = c1+1:n_chanels
            % Calculate GC
            GC = GCmodel(chunk([c1,c2],:),order);
            GC = max(GC,[0 0]);
            conn(c1,c2) = GC(1);
            conn(c2,c1) = GC(2);
        end
    end

    conectivityMatrix = conn;
end

