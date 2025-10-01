function [x_loads, F_loads] = distributePointLoad(F_total, x0, x_available, sigma, plotFlag)
    % Distributes a point load using a Gaussian distribution
    %
    % Inputs:
    %   F_total      - Total force magnitude (scalar)
    %   x0           - Location of original point load
    %   x_available  - Vector of available x-coordinates (non-uniform)
    %   sigma        - Standard deviation of Gaussian distribution
    %   plotFlag     - (optional) true to show plot, false otherwise (default: false)
    %
    % Outputs:
    %   x_loads      - x-coordinates where loads are applied
    %   F_loads      - Magnitude of load at each x-coordinate
    
    if nargin < 5
        plotFlag = false;
    end
    
    % Evaluate Gaussian at each available point
    gaussian_weights = exp(-((x_available - x0).^2) / (2 * sigma^2));
    
    % Normalize so sum equals F_total
    F_loads = F_total * gaussian_weights / sum(gaussian_weights);
    
    % Return the coordinates
    x_loads = x_available;
    
    % Optional: filter out very small loads (< 0.1% of total)
    threshold = 0.001 * F_total;
    keep_idx = F_loads > threshold;
    x_loads = x_loads(keep_idx);
    F_loads = F_loads(keep_idx);
    
    % Renormalize after filtering
    F_loads = F_total * F_loads / sum(F_loads);
    
    % Plot if requested
    if plotFlag
        figure;
        
        % Create continuous Gaussian curve for reference
        x_continuous = linspace(min(x_available), max(x_available), 200);
        gaussian_continuous = exp(-((x_continuous - x0).^2) / (2 * sigma^2));
        gaussian_continuous = F_total * gaussian_continuous / sum(gaussian_weights);
        
        % Plot continuous Gaussian
        plot(x_continuous, gaussian_continuous, 'b-', 'LineWidth', 1.5, ...
             'DisplayName', 'Continuous Gaussian');
        hold on;
        
        % Plot distributed loads as stems
        stem(x_loads, F_loads, 'filled', 'LineWidth', 2, 'MarkerSize', 8, ...
             'Color', [0.85, 0.33, 0.1], 'DisplayName', 'Distributed loads');
        
        % Mark original load location
        plot(x0, F_total, 'rx', 'MarkerSize', 15, 'LineWidth', 3, ...
             'DisplayName', 'Original load location');
        
        % Mark all available points (even those with zero/filtered loads)
        plot(x_available, zeros(size(x_available)), 'ko', 'MarkerSize', 4, ...
             'DisplayName', 'Available grid points');
        
        xlabel('Position (m)', 'FontSize', 12);
        ylabel('Force (N)', 'FontSize', 12);
        title(sprintf('Gaussian Distribution of Point Load (\\sigma = %.2f m)', sigma), ...
              'FontSize', 13);
        legend('Location', 'best');
        grid on;
        
        % Add text box with summary
        textStr = sprintf(['Total Force: %.2f N\n' ...
                          'Number of loads: %d\n' ...
                          'Sum check: %.2f N'], ...
                          F_total, length(x_loads), sum(F_loads));
        annotation('textbox', [0.15, 0.75, 0.25, 0.15], 'String', textStr, ...
                   'BackgroundColor', 'white', 'EdgeColor', 'black', ...
                   'FontSize', 10, 'FitBoxToText', 'on');
        
        hold off;
    end
end