function out = visualiseData(data)
    num_matrices = size(data,3);
    
    num_rows = ceil(sqrt(num_matrices));
    num_cols = ceil(num_matrices / num_rows);
    
    global_min = min(data(:));
    global_max = max(data(:));
    
    %plot each
    for i = 1:num_matrices
        
        matrix = data(:,:,i);
        
        subplot(num_rows, num_cols, i); 
        imagesc(matrix);
        colormap('jet'); 
        caxis([global_min global_max]); 
        axis off; 
        
        text(0.5, 0.5, num2str(i), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 10, 'Color', 'black');
    end
   
    colorbar;
    
    out = 0;
end
