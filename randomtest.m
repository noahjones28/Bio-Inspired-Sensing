% Define parameter ranges
F_range = linspace(0.05, 1, 10);      % Adjust range as needed
s_range = linspace(0.01, 0.2, 10);     % Adjust range as needed
theta_range = linspace(0.0, pi, 2);   % Add theta as third parameter

% Create meshgrid for all three parameters
% meshgrid output dimensions: [length(s), length(F), length(theta)]
[F_grid, s_grid, theta_grid] = meshgrid(F_range, s_range, theta_range);

% Initialize output arrays
Ty_grid = zeros(size(F_grid));
Tz_grid = zeros(size(F_grid));
Fx_grid = zeros(size(F_grid));

% Loop through all F, s, theta combinations
for i = 1:numel(F_grid)
    result = get_proximal_value([F_grid(i), s_grid(i), theta_grid(i)]);
    Ty_grid(i) = result(2);  % Ty is 2nd element
    Tz_grid(i) = result(3);  % Tz is 3rd element
    Fx_grid(i) = result(4);  % Fx is 4th element
end

% Create figure with monochromatic surfaces
figure('Position', [100 100 1600 500]);

% Plot 1: Surfaces colored by F (F is 2nd dimension)
subplot(1,3,1)
hold on
for i = 1:length(F_range)
    % Extract the surface for this F value (varies over s and theta)
    Ty_surf = squeeze(Ty_grid(:,i,:));
    Tz_surf = squeeze(Tz_grid(:,i,:));
    Fx_surf = squeeze(Fx_grid(:,i,:));
    
    % Plot surface with color corresponding to F value
    surf(Tz_surf, Fx_surf, Ty_surf, 'FaceColor', 'flat', ...
        'FaceAlpha', 0.7, 'EdgeColor', 'none', ...
        'CData', ones(size(Ty_surf))*F_range(i));
end
xlabel('Tz'); ylabel('Fx'); zlabel('Ty')
title('Colored by F')
colorbar
grid on
view(3)
hold off

% Plot 2: Surfaces colored by s (s is 1st dimension)
subplot(1,3,2)
hold on
for j = 1:length(s_range)
    % Extract the surface for this s value (varies over F and theta)
    Ty_surf = squeeze(Ty_grid(j,:,:));
    Tz_surf = squeeze(Tz_grid(j,:,:));
    Fx_surf = squeeze(Fx_grid(j,:,:));
    
    % Plot surface with color corresponding to s value
    surf(Tz_surf, Fx_surf, Ty_surf, 'FaceColor', 'flat', ...
        'FaceAlpha', 0.7, 'EdgeColor', 'none', ...
        'CData', ones(size(Ty_surf))*s_range(j));
end
xlabel('Tz'); ylabel('Fx'); zlabel('Ty')
title('Colored by s')
colorbar
grid on
view(3)
hold off

% Plot 3: Surfaces colored by theta (theta is 3rd dimension)
subplot(1,3,3)
hold on
for k = 1:length(theta_range)
    % Extract the surface for this theta value (varies over s and F)
    Ty_surf = squeeze(Ty_grid(:,:,k));
    Tz_surf = squeeze(Tz_grid(:,:,k));
    Fx_surf = squeeze(Fx_grid(:,:,k));
    
    % Plot surface with color corresponding to theta value
    surf(Tz_surf, Fx_surf, Ty_surf, 'FaceColor', 'flat', ...
        'FaceAlpha', 0.7, 'EdgeColor', 'none', ...
        'CData', ones(size(Ty_surf))*theta_range(k));
end
xlabel('Tz'); ylabel('Fx'); zlabel('Ty')
title('Colored by \theta')
colorbar
grid on
view(3)
hold off

% Enable rotation for all subplots
for i = 1:3
    subplot(1,3,i)
    rotate3d on
end