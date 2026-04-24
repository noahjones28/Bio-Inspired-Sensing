function conditioning_validation()
% CONDITIONING_VALIDATION  Compare Jacobian conditioning of cylindrical vs.
%   optimized backbone designs on training and unseen loading configurations.

close all; clc;

%% Parameters
n_test_forces = 5;
F_range       = [0.3, 1.5];
s_range       = [0.02, 0.20];
theta_range   = [0, 2*pi];
tau_range     = [0, 3];
s_sep_min     = 0.02;
results_file  = 'conditioning_validation_results.xlsx';

%% Design vectors
x_cylindrical = repmat([0.0020 0.0020 0], 1, 20);
x_optimized   = [0.004321195 0.005827595 0 0.003393374 0.004755388 0.425779781 ...
                 0.004809034 0.004582241 0.439620542 0.004328871 0.001372408 0.021058184 ...
                 0.00591088  0.005612765 0.63397581  0.002437818 0.005476283 0.38236099 ...
                 0.004054928 0.001445563 0.210649505 0.00170973  0.002089987 0.37013945 ...
                 0.001726739 0.002097435 0.102848983 0.001240948 0.00390915  1.365199871 ...
                 0.001725348 0.001866223 0.836677127 0.001724622 0.00176954  0.26512952 ...
                 0.002463568 0.001351542 0.375414947 0.002498896 0.001275632 0.985984478 ...
                 0.002105341 0.001272395 0.522904698 0.003184076 0.002394019 0.15824516 ...
                 0.004451075 0.005160032 0.482727989 0.005470347 0.005003258 0.870955283 ...
                 0.005547149 0.005756296 1.126630507 0.005483462 0.005218588 1.150931239];

%% Load from spreadsheet if it exists, otherwise compute and save
if isfile(results_file)
    fprintf('Loading cached results from %s\n', results_file);
    T_cyl_train  = readtable(results_file, 'Sheet', 'cyl_train');
    T_cyl_unseen = readtable(results_file, 'Sheet', 'cyl_unseen');
    T_opt_train  = readtable(results_file, 'Sheet', 'opt_train');
    T_opt_unseen = readtable(results_file, 'Sheet', 'opt_unseen');

    sep_cyl_train   = T_cyl_train.separation_mm;
    cond_cyl_train  = T_cyl_train.condition_number;
    sep_cyl_unseen  = T_cyl_unseen.separation_mm;
    cond_cyl_unseen = T_cyl_unseen.condition_number;
    sep_opt_train   = T_opt_train.separation_mm;
    cond_opt_train  = T_opt_train.condition_number;
    sep_opt_unseen  = T_opt_unseen.separation_mm;
    cond_opt_unseen = T_opt_unseen.condition_number;
else
    fprintf('Computing results (this may take a while)...\n\n');

    [cond_cyl_train,  sep_cyl_train]  = run_case(x_cylindrical, 'Cylindrical (train)',  n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, 1234);
    [cond_cyl_unseen, sep_cyl_unseen] = run_case(x_cylindrical, 'Cylindrical (unseen)', n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, 5678);
    [cond_opt_train,  sep_opt_train]  = run_case(x_optimized,   'Optimized (train)',     n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, 1234);
    [cond_opt_unseen, sep_opt_unseen] = run_case(x_optimized,   'Optimized (unseen)',    n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, 5678);

    % Save to spreadsheet
    writetable(table(sep_cyl_train,  cond_cyl_train,  'VariableNames', {'separation_mm','condition_number'}), results_file, 'Sheet', 'cyl_train');
    writetable(table(sep_cyl_unseen, cond_cyl_unseen, 'VariableNames', {'separation_mm','condition_number'}), results_file, 'Sheet', 'cyl_unseen');
    writetable(table(sep_opt_train,  cond_opt_train,  'VariableNames', {'separation_mm','condition_number'}), results_file, 'Sheet', 'opt_train');
    writetable(table(sep_opt_unseen, cond_opt_unseen, 'VariableNames', {'separation_mm','condition_number'}), results_file, 'Sheet', 'opt_unseen');
    fprintf('\nResults saved to %s\n', results_file);
end

%% Print summary
fprintf('\n=== Summary ===\n');
fprintf('%-25s  %-14s %s\n', '', 'Mean K', 'Max K');
fprintf('%-25s  %-14.2e %.2e\n', 'Cylindrical  (train)',  mean(cond_cyl_train),  max(cond_cyl_train));
fprintf('%-25s  %-14.2e %.2e\n', 'Cylindrical  (unseen)', mean(cond_cyl_unseen), max(cond_cyl_unseen));
fprintf('%-25s  %-14.2e %.2e\n', 'Optimized    (train)',  mean(cond_opt_train),  max(cond_opt_train));
fprintf('%-25s  %-14.2e %.2e\n', 'Optimized    (unseen)', mean(cond_opt_unseen), max(cond_opt_unseen));

%% Plot
plot_validation(sep_cyl_train, cond_cyl_train, sep_cyl_unseen, cond_cyl_unseen, ...
                sep_opt_train, cond_opt_train, sep_opt_unseen, cond_opt_unseen);
end

%% ========================================================================
function [cond_nums, separations] = run_case(x_design, label, n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, rng_seed)

    fprintf('\n--- %s  (rng %d) ---\n', label, rng_seed);

    % Set design geometry
    update_design(x_design);

    % Generate test forces
    test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, rng_seed);

    % Force separation |s1 - s2| in mm
    separations = abs(test_forces(:,2) - test_forces(:,5)) * 1000;

    % Whitened Jacobian
    [Jw, ~] = compute_jacobian(test_forces(:,1:6), test_forces(:,end-2:end));

    % Condition numbers
    cond_nums = zeros(n_test_forces, 1);
    for i = 1:n_test_forces
        k = cond(Jw{i});
        cond_nums(i) = k;
        fprintf('  Config %2d:  K = %.4e   |s1-s2| = %.1f mm\n', i, k, separations(i));
    end

    fprintf('  Mean K = %.4e\n', mean(cond_nums));
end

%% ========================================================================
function plot_validation(sep_ct, k_ct, sep_cu, k_cu, sep_ot, k_ot, sep_ou, k_ou)

    col_cyl = [0.42 0.45 0.50];
    col_opt = [0 198/255 215/255];
    ms = 55;

    figure('Position', [100 100 820 480], 'Color', 'w');
    hold on;

    % Cylindrical
    h1 = scatter(sep_ct, k_ct, ms, col_cyl, 'o', 'LineWidth', 1.5);
    h2 = scatter(sep_cu, k_cu, ms, col_cyl, 'o', 'filled', 'MarkerFaceAlpha', 0.7);

    % Optimized
    h3 = scatter(sep_ot, k_ot, ms, col_opt, 'o', 'LineWidth', 1.5);
    h4 = scatter(sep_ou, k_ou, ms, col_opt, 'o', 'filled', 'MarkerFaceAlpha', 0.7);

    set(gca, 'YScale', 'log');
    xlabel('|s_1 - s_2|  (mm)');
    ylabel('cond(J)');

    legend([h1 h2 h3 h4], ...
        {'Cylindrical — design loads', 'Cylindrical — unseen loads', ...
         'Optimized — design loads',   'Optimized — unseen loads'}, ...
        'Location', 'northeast', 'FontSize', 10);

    grid on;
    set(gca, 'FontSize', 16, 'GridAlpha', 0.15, 'FontWeight', 'bold');
    xlim([0, inf]);
    hold off;

    exportgraphics(gcf, 'conditioning_validation.png', 'Resolution', 300, 'BackgroundColor', 'none');
    fprintf('\nPlot saved to conditioning_validation.png\n');
end

%% ========================================================================
function test_forces = generate_test_forces(n_test_forces, F_range, s_range, theta_range, tau_range, s_sep_min, rng_seed)
    rng(rng_seed);

    U = lhsdesign(n_test_forces, 9, 'criterion', 'maximin', 'iterations', 50);
    scale = @(u,r) r(1) + u.*diff(r);

    F1   = scale(U(:,1), F_range);
    F2   = scale(U(:,2), F_range);
    t1   = scale(U(:,3), theta_range);
    t2   = scale(U(:,4), theta_range);
    tau1 = scale(U(:,5), tau_range);
    tau2 = scale(U(:,6), tau_range);
    tau3 = scale(U(:,7), tau_range);

    s_raw1 = scale(U(:,8), s_range);
    s_raw2 = scale(U(:,9), s_range);
    s1 = max(s_raw1, s_raw2);
    s2 = min(s_raw1, s_raw2);

    too_close = (s1 - s2) < s_sep_min;
    while any(too_close)
        n_fix = sum(too_close);
        s_new1 = s_range(1) + rand(n_fix,1) * diff(s_range);
        s_new2 = s_range(1) + rand(n_fix,1) * diff(s_range);
        s1(too_close) = max(s_new1, s_new2);
        s2(too_close) = min(s_new1, s_new2);
        too_close = (s1 - s2) < s_sep_min;
    end

    test_forces = [F1, s1, t1, F2, s2, t2, tau1, tau2, tau3];
end