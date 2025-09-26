function validation_results = validateJacobian(S1, q, J_analytical, params0)
% Validates the analytical Jacobian against numerical finite differences
% Inputs:
%   S1 - SorosimLinkage object
%   q - Configuration from S1.statics()
%   J_analytical - Your calculated 6x4 Jacobian
%   params0 - Nominal parameters [F; s; el; az] (optional)
% Output:
%   validation_results - Struct with validation metrics and plots

    % Default parameters if not provided
    if nargin < 4
        params0 = [10; 0.5; pi/4; pi/6];  % [F, s, el, az]
    end
    
    % Finite difference step
    delta = 1e-6;
    
    %% Compute Numerical Jacobian
    J_numerical = zeros(6, 4);
    
    % Baseline wrench
    W0 = get_proximal_value([params0(1), params0(2), params0(3), params0(4)],[0,0,0], false);
    
    % Central differences for each parameter
    for i = 1:4
        params_plus = params0;
        params_minus = params0;
        params_plus(i) = params0(i) + delta;
        params_minus(i) = params0(i) - delta;
        
        W_plus = get_proximal_value([params_plus(1), params_plus(2), ...
                                    params_plus(3), params_plus(4)],[0,0,0], false);
        W_minus = get_proximal_value([params_minus(1), params_minus(2), ...
                                     params_minus(3), params_minus(4)],[0,0,0], false);
        
        J_numerical(:, i) = (W_plus - W_minus) / (2*delta);
    end
    
    %% Compute Error Metrics
    diff_matrix = J_analytical - J_numerical;
    rel_error_matrix = abs(diff_matrix) ./ (abs(J_numerical) + 1e-10);
    
    frob_error = norm(diff_matrix, 'fro');
    frob_relative = frob_error / (norm(J_numerical, 'fro') + 1e-10);
    max_error = max(abs(diff_matrix(:)));
    
    %% Store Results
    validation_results.J_analytical = J_analytical;
    validation_results.J_numerical = J_numerical;
    validation_results.error_matrix = diff_matrix;
    validation_results.relative_error = rel_error_matrix;
    validation_results.frob_error = frob_error;
    validation_results.frob_relative = frob_relative;
    validation_results.max_error = max_error;
    validation_results.passed = frob_relative < 1e-3;
    
    %% Display Results
    fprintf('\n========== JACOBIAN VALIDATION ==========\n');
    fprintf('Configuration: q from statics\n');
    fprintf('Parameters: F=%.2f, s=%.2f, el=%.2f°, az=%.2f°\n', ...
            params0(1), params0(2), rad2deg(params0(3)), rad2deg(params0(4)));
    fprintf('\n--- Error Metrics ---\n');
    fprintf('Frobenius norm error: %.6e\n', frob_error);
    fprintf('Relative error: %.4f%%\n', frob_relative * 100);
    fprintf('Max absolute error: %.6e\n', max_error);
    
    if validation_results.passed
        fprintf('✓ VALIDATION PASSED\n');
    else
        fprintf('✗ VALIDATION FAILED - Check your Jacobian\n');
    end
    
    %% Visualization
    figure('Name', 'Jacobian Validation', 'Position', [100, 100, 1000, 600]);
    
    % Analytical vs Numerical
    subplot(2, 3, 1);
    imagesc(J_analytical);
    colorbar;
    title('Your Jacobian');
    set(gca, 'XTick', 1:4, 'XTickLabel', {'F', 's', 'el', 'az'});
    set(gca, 'YTick', 1:6, 'YTickLabel', {'Tx', 'Ty', 'Tz', 'Fx', 'Fy', 'Fz'});
    
    subplot(2, 3, 2);
    imagesc(J_numerical);
    colorbar;
    title('Numerical Jacobian');
    set(gca, 'XTick', 1:4, 'XTickLabel', {'F', 's', 'el', 'az'});
    set(gca, 'YTick', 1:6, 'YTickLabel', {'Tx', 'Ty', 'Tz', 'Fx', 'Fy', 'Fz'});
    
    subplot(2, 3, 3);
    imagesc(log10(abs(diff_matrix) + 1e-16));
    colorbar;
    title('Log10(Absolute Error)');
    set(gca, 'XTick', 1:4, 'XTickLabel', {'F', 's', 'el', 'az'});
    set(gca, 'YTick', 1:6, 'YTickLabel', {'Tx', 'Ty', 'Tz', 'Fx', 'Fy', 'Fz'});
    
    % Bar comparison
    subplot(2, 3, 4:6);
    x = 1:24;
    y_analytical = J_analytical(:);
    y_numerical = J_numerical(:);
    
    bar(x-0.2, y_analytical, 0.4, 'b', 'DisplayName', 'Analytical');
    hold on;
    bar(x+0.2, y_numerical, 0.4, 'r', 'DisplayName', 'Numerical');
    xlabel('Jacobian Element Index');
    ylabel('Value');
    title('Element-wise Comparison');
    legend();
    grid on;
    
    %% Linearity Check
    fprintf('\n--- Linearity Check ---\n');
    
    % Small perturbation
    dparams = 0.01 * randn(4, 1);
    
    % Predict using Jacobian
    dW_predicted = J_analytical * dparams;
    
    % Actual change
    params_new = params0 + dparams;
    W_new = get_proximal_value(params_new(1), params_new(2), ...
                               params_new(3), params_new(4));
    dW_actual = W_new - W0;
    
    linearity_error = norm(dW_predicted - dW_actual) / norm(dW_actual);
    fprintf('Linearization relative error: %.4f%%\n', linearity_error * 100);
    
    validation_results.linearity_error = linearity_error;
    
    fprintf('=========================================\n');
end