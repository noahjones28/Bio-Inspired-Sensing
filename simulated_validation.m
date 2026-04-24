function [estimates_cyl, estimates_opt] = simulated_validation(distal_values)
    close all; clc;

    %% Design vectors
    x_cylindrical = repmat([0.0020 0.0020 0], 1, 20);

    x_optimized = [0.004321195 0.005827595 0.000000000  0.003393374 0.004755388 0.425779781 ...
                   0.004809034 0.004582241 0.439620542  0.004328871 0.001372408 0.021058184 ...
                   0.005910880 0.005612765 0.633975810  0.002437818 0.005476283 0.382360990 ...
                   0.004054928 0.001445563 0.210649505  0.001709730 0.002089987 0.370139450 ...
                   0.001726739 0.002097435 0.102848983  0.001240948 0.003909150 1.365199871 ...
                   0.001725348 0.001866223 0.836677127  0.001724622 0.001769540 0.265129520 ...
                   0.002463568 0.001351542 0.375414947  0.002498896 0.001275632 0.985984478 ...
                   0.002105341 0.001272395 0.522904698  0.003184076 0.002394019 0.158245160 ...
                   0.004451075 0.005160032 0.482727989  0.005470347 0.005003258 0.870955283 ...
                   0.005547149 0.005756296 1.126630507  0.005483462 0.005218588 1.150931239];
    
    %% Extract tendon tensions from input (shared by both designs)
    num_samples = size(distal_values, 1);
    tau = distal_values(:, 7:9);  % Nx3 tendon tensions [tau1, tau2, tau3]

    %% Cylindrical design
    S_cyl        = update_design(x_cylindrical);
    proximal_cyl = forward_model_parallel(distal_values, S_cyl);            % Nx6 wrenches
    prox_cell_cyl = build_proximal_cells(proximal_cyl, tau, num_samples);   % cell array of 1x9
    estimates_cyl = inverse_model_parallel(prox_cell_cyl);                  % no S argument

    %% Optimized design
    S_opt        = update_design(x_optimized);
    proximal_opt = forward_model_parallel(distal_values, S_opt);            % Nx6 wrenches
    prox_cell_opt = build_proximal_cells(proximal_opt, tau, num_samples);   % cell array of 1x9
    estimates_opt = inverse_model_parallel(prox_cell_opt);                  % FIX: was estimates_cyl

    %% Display results
    fprintf('\n=== Cylindrical Design Estimates ===\n');
    disp(estimates_cyl);
    fprintf('\n=== Optimized Design Estimates ===\n');
    disp(estimates_opt);
end

function prox_cells = build_proximal_cells(proximal_matrix, tau, num_samples)
% Combines Nx6 proximal wrenches with Nx3 tendon tensions into
% a cell array of 1x9 vectors for inverse_model_parallel.
    prox_cells = cell(num_samples, 1);
    for i = 1:num_samples
        prox_cells{i} = [proximal_matrix(i, :), tau(i, :)];  % 1x9: [Tx Ty Tz Fx Fy Fz tau1 tau2 tau3]
    end
end