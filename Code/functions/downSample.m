function [ds_data,ds_markers] = downSample(data,markers)
    arguments
        data (:,:,:) double
        markers (1,:) double
    end

    [counts, unique_values] = groupcounts(markers');
    counts = counts';
    unique_values = unique_values';
    min_count = min(counts);
    
    ds_data = [];
    ds_markers = [];
    
    %randomy chose the amout needed of each
    for i = 1:length(unique_values)
    
        idx = find(markers == unique_values(i));
        selected_idx = idx(randperm(length(idx), min_count)); 
        ds_data = cat(3, ds_data, data(:, :, selected_idx));
        ds_markers = [ds_markers, markers(selected_idx)];
    
    end
    
    %permutate
    perm = randperm(length(ds_markers));
    ds_data = ds_data(:, :, perm);
    ds_markers = ds_markers(perm);


end

