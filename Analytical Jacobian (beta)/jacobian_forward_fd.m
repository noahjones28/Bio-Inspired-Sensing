function [J, y0] = jacobian_forward_fd(f, x0)
    % Forward difference Jacobian for 6×6 system
    % x0 is 2×3: [F1 s1 el1; F2 s2 el2]
    
    y0 = f(x0);
    m = numel(y0);  % Should be 6
    n = 4;          % 6 parameters total
    J = zeros(m, n);
    
    % Step sizes
    h = [1e-4, 1e-4, 1e-4, 1e-4];
    
    % Parameter positions in 2×3 matrix
    param_positions = [1,1; 1,2; 2,1; 2,2;];
    
    for k = 1:n
        x_plus = x0;
        row_idx = param_positions(k,1);
        col_idx = param_positions(k,2);
        x_plus(row_idx, col_idx) = x_plus(row_idx, col_idx) + h(k);
        
        yph = f(x_plus);
        J(:,k) = (yph - y0) / h(k);
    end
end