function test_taper_designs()
    % Paramaters
    lb = 1e-3*[0.5, 0.5]; % upper & lower bound on [r1, r2]
    ub = 1e-3*[2.0, 2.0];
    n_designs = 20; % num designs to sample
    designs = get_space_filling_points(lb, ub, n_designs, 'lhs');
    
    % Generate design names
    design_names = cell(n_designs, 1);
    results = zeros(n_designs, 4);
    
    % Test each design
    fprintf('Testing %d taper designs...\n', n_designs);
    for i = 1:n_designs
        r1 = designs(i, 1);
        r2 = designs(i, 2);
        design_names{i} = sprintf('[%.2e, %.2e]', r1, r2);
        fprintf('  Testing design %d: %s\n', i, design_names{i});
        r = [r1, r2];
        
        % Update radius of my_robot in current directory
        update_radius(r, "tapered")
        [~, mae_F, mae_s, mae_theta, mae_weighted] = evaluate_inverse_accuracy();
        results(i, :) = [mae_F, mae_s, mae_theta, mae_weighted];
    end
    
    % Plot results
    plot_design_comparison(results, designs, lb, ub);
    fprintf('Testing complete!\n');
end

function plot_design_comparison(results, designs, lb, ub)
    % results: n_designs x 4 matrix
    % designs: n_designs x 2 matrix [r1, r2]
    
    r1 = designs(:, 1);
    r2 = designs(:, 2);
    
    error_labels = {'Force Error (MAE_F)', 'Position Error (MAE_s)', ...
                    'Angle Error (MAE_θ)', 'Weighted Error (MAE_weighted)'};
    
    figure('Position', [100, 100, 1400, 800]);
    
    for i = 1:4
        subplot(2, 2, i);
        
        % Create interpolant for smooth transitions
        F = scatteredInterpolant(r1, r2, results(:, i), 'linear', 'linear');
        
        % Create grid for interpolation using bounds
        r1_grid = linspace(lb(1), ub(1), 100);
        r2_grid = linspace(lb(2), ub(2), 100);
        [R1, R2] = meshgrid(r1_grid, r2_grid);
        
        % Interpolate and plot heatmap
        Z = F(R1, R2);
        imagesc(r1_grid, r2_grid, Z);
        hold on;
        
        % Draw cylindrical design line (r1 = r2)
        r_start = max(lb(1), lb(2));
        r_end = min(ub(1), ub(2));
        plot([r_start, r_end], [r_start, r_end], 'r-', 'LineWidth', 2);
        
        % Plot all samples
        scatter(r1, r2, 50, 'k', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
        
        % Find and mark the best design (minimum error)
        [~, best_idx] = min(results(:, i));
        scatter(r1(best_idx), r2(best_idx), 200, 'm', 'p', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 1.5);
        
        hold off;
        
        colorbar;
        xlabel('r1');
        ylabel('r2');
        title(error_labels{i});
        axis xy; % Correct axis orientation
        xlim([lb(1), ub(1)]);
        ylim([lb(2), ub(2)]);
    end
    
    % Add single legend for all subplots
    lgd = legend('Cylindrical (r1=r2)', 'Samples', 'Best Design');
    lgd.Position = [0.45, 0.02, 0.1, 0.05]; % Centered at bottom
    
    sgtitle('Taper Design Comparison', 'FontSize', 14, 'FontWeight', 'bold');
end