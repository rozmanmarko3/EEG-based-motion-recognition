% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib,'type','EEG'); end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

disp('Now receiving chunked data...');



r_values = strings(1, 4);
counter = 0;

while true
    [chunk, stamps] = inlet.pull_chunk();
    r = liveFunction(chunk);
    r_values(counter + 1) = string(r);
    counter = counter + 1;
    
    if counter == 4
        [unique_r, ~, idx] = unique(r_values);
        counts = histc(idx, 1:numel(unique_r));
        [~, max_idx] = max(counts);
        rnew = unique_r(max_idx);
        disp(rnew);
        counter = 0;
        r_values = strings(1, 4);
    end
    
    pause(0.25);
end


