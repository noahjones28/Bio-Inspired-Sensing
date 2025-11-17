% Run both configurations
update_radius(1.5e-3, "cylindrical");
[~, mae_F1, mae_s1, mae_theta1, ~, distal1, estimated1] = evaluate_inverse_accuracy();

update_radius([1.7e-3, 1.25e-3], "tapered");
[~, mae_F2, mae_s2, mae_theta2, ~, distal2, estimated2] = evaluate_inverse_accuracy();

% Overlay plot
figure;
colors = [0 0.447 0.741; 0.85 0.325 0.098];

subplot(1, 3, 1);
scatter(distal1(:,1), estimated1(:,1), 70, colors(1,:), 'filled', 'DisplayName', 'Cylindrical');
hold on;
scatter(distal2(:,1), estimated2(:,1), 70, colors(2,:), 'filled', 'DisplayName', 'Tapered');
plot([0.1 0.8], [0.1 0.8], 'k--', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xlabel('Ground Truth F'); ylabel('Predicted F');
title(sprintf('F (%.4f / %.4f)', mae_F1, mae_F2));
legend; axis equal tight; grid on;

subplot(1, 3, 2);
scatter(distal1(:,2), estimated1(:,2), 70, colors(1,:), 'filled');
hold on;
scatter(distal2(:,2), estimated2(:,2), 70, colors(2,:), 'filled');
plot([0.06 0.2], [0.06 0.2], 'k--', 'LineWidth', 1.5);
xlabel('Ground Truth s'); ylabel('Predicted s');
title(sprintf('s (%.4f / %.4f)', mae_s1, mae_s2));
axis equal tight; grid on;

subplot(1, 3, 3);
scatter(distal1(:,3), estimated1(:,3), 70, colors(1,:), 'filled');
hold on;
scatter(distal2(:,3), estimated2(:,3), 70, colors(2,:), 'filled');
plot([1.5 1.6], [1.5 1.6], 'k--', 'LineWidth', 1.5);
xlabel('Ground Truth \theta'); ylabel('Predicted \theta');
title(sprintf('\\theta (%.4f / %.4f)', mae_theta1, mae_theta2));
axis equal tight; grid on;