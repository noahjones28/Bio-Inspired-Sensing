function [row_vector, row_index] = findClosestRow(filename, sheet, column, tau)
    % Read only columns 1-7 as numeric matrix
    data = readmatrix(filename, 'Sheet', sheet, 'Range', 'A:G');
    
    % Extract the specified column
    search_column = data(:, column);
    
    % Find the index of the closest value to tau
    [~, row_index] = min(abs(search_column - abs(tau)));
    
    % Extract columns 2-7
    row_vector = data(row_index, 2:7);
end