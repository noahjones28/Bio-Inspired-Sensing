function plot_cross_section_evolution(x_design, r_cyl, img_path)
% PLOT_CROSS_SECTION_EVOLUTION  Visualize optimized backbone cross-sections.
%
%   plot_cross_section_evolution(x_design) plots the cross-section evolution
%   along the backbone for a given design vector.
%
%   plot_cross_section_evolution(x_design, r_cyl) also specifies the
%   cylindrical baseline radius in mm (default: 3.175 mm).
%
%   plot_cross_section_evolution(x_design, r_cyl, img_path) places an image
%   (e.g. CAD rendering or photograph) at the top of the figure.
%
%   INPUT:
%       x_design  - 1x60 design vector: [a1, b1, phi1, ..., a20, b20, phi20]
%       r_cyl     - (optional) cylindrical baseline radius in mm (default 3.175).
%       img_path  - (optional) path to CAD/photo image file.

    if nargin < 2 || isempty(r_cyl)
        r_cyl = 3.175;
    end
    if nargin < 3
        img_path = '';
    end

    % ── Parse design vector ──
    N = 20;
    a   = zeros(1, N);
    b   = zeros(1, N);
    phi = zeros(1, N);
    for i = 1:N
        a(i)   = x_design(3*(i-1) + 1);
        b(i)   = x_design(3*(i-1) + 2);
        phi(i) = x_design(3*(i-1) + 3);
    end

    % ── Derived quantities ──
    arc_pos       = (1:N) * 10;
    areas         = pi * a .* b;
    aspect_ratios = max(a,b) ./ min(a,b);
    phi_deg       = rad2deg(phi);
    area_cyl      = pi * r_cyl^2;

    % ── Colors ──
    c_opt      = [0.169 0.357 0.627];
    c_purple   = [0.486 0.228 0.929];
    c_green    = [0.020 0.588 0.404];
    c_cyl_rgb  = [0.53 0.53 0.53];

    % ── Create figure ──
    fig = figure('Units','inches','Position',[1 0.5 7.5 10.0], ...
                 'Color','w','PaperPositionMode','auto');

    % ── Layout constants ──
    pw = 0.80;  pl = 0.15;
    gap = 0.018;
    h_img = 0.12;   h_a = 0.32;   h_bar = 0.115;

    bot_d   = 0.065;
    bot_c   = bot_d + h_bar + gap;
    bot_b   = bot_c + h_bar + gap;
    bot_a   = bot_b + h_bar + gap + 0.055;
    bot_img = bot_a + h_a + 0.015;

    % ═══════════════════════════════════════════
    % Image / placeholder at top
    % ═══════════════════════════════════════════
    ax_img = axes('Position', [pl bot_img pw h_img]);
    hold on;

    if ~isempty(img_path) && isfile(img_path)
        img = imread(img_path);
        image([0 200], [1 -1], img);
        set(ax_img, 'YDir','normal');
    else
        rectangle('Position',[1 -0.85 198 1.7], 'LineStyle','--', ...
                  'EdgeColor',[0.73 0.73 0.73], 'LineWidth',1);
        text(100, 0, 'Insert CAD rendering or photograph here', ...
             'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
             'FontSize',10, 'Color',[0.67 0.67 0.67], 'FontAngle','italic');
    end

    % Base / Tip labels
    text(5, -1.3, {'Base'}, 'FontSize',10, 'FontWeight','bold', ...
         'Color',[0.27 0.27 0.27], 'HorizontalAlignment','left', ...
         'VerticalAlignment','top');
    text(195, -1.3, {'Tip'}, 'FontSize',10, 'FontWeight','bold', ...
         'Color',[0.27 0.27 0.27], 'HorizontalAlignment','right', ...
         'VerticalAlignment','top');

    % Scale bar arrow
    annotation('doublearrow', ...
        [pl + (10/200)*pw,  pl + (190/200)*pw], ...
        [bot_img + 0.015,   bot_img + 0.015], ...
        'Head1Style','vback2', 'Head2Style','vback2', ...
        'Head1Length',5, 'Head2Length',5, ...
        'Color',[0.33 0.33 0.33], 'LineWidth',1.2);
    annotation('textbox', ...
        [pl + pw*0.35, bot_img + 0.003, pw*0.3, 0.02], ...
        'String','200 mm', 'FontSize',10, 'FontWeight','bold', ...
        'Color',[0.33 0.33 0.33], 'HorizontalAlignment','center', ...
        'VerticalAlignment','middle', 'EdgeColor','none', ...
        'BackgroundColor','w');

    xlim([0 200]); ylim([-1.6 1]);
    axis off; hold off;

    % ═══════════════════════════════════════════
    % Panel (a): 2 rows x 10 columns of cross-sections
    % ═══════════════════════════════════════════
    ax_bg = axes('Position', [pl bot_a pw h_a]);
    set(ax_bg, 'XLim',[0 10], 'YLim',[0 2]);
    axis off;

    text(-0.09, 1.0, '(a)', 'Units','normalized', 'FontSize',13, ...
         'FontWeight','bold', 'VerticalAlignment','top');

    % ── Grid dimensions (reduced vertical gap) ──
    margin_y_top = 0.008;
    margin_y_bot = 0.045;
    row_gap = 0.012;
    cell_w = pw / 10;
    cell_h = (h_a - margin_y_top - margin_y_bot - row_gap) / 2;
    cell_size = min(cell_w, cell_h);

    grid_w = cell_size * 10;
    x_offset = pl + (pw - grid_w) / 2;

    row_tops = [bot_a + h_a - margin_y_top - cell_size, ...
                bot_a + margin_y_bot];

    max_dim = max(max(a), max(b));
    cell_half = max_dim * 1.1;

    theta_ell = linspace(0, 2*pi, 120);

    for i = 1:N
        row = ceil(i / 10);
        col = mod(i - 1, 10);

        x_pos = x_offset + col * cell_size;
        y_pos = row_tops(row);

        ax_m = axes('Position', [x_pos, y_pos, cell_size, cell_size]);
        hold on;

        % Cylindrical baseline circle
        plot(r_cyl*cos(theta_ell), r_cyl*sin(theta_ell), '--', ...
             'Color',[c_cyl_rgb 0.5], 'LineWidth',0.8);

        % Optimized ellipse (rotated)
        ex = a(i) * cos(theta_ell);
        ey = b(i) * sin(theta_ell);
        rx = ex * cos(phi(i)) - ey * sin(phi(i));
        ry = ex * sin(phi(i)) + ey * cos(phi(i));

        fill(rx, ry, c_opt, 'FaceAlpha',0.20, 'EdgeColor',c_opt, ...
             'LineWidth',1.4);

        plot(0, 0, '.', 'Color',[0.2 0.2 0.2], 'MarkerSize',4);

        % Semi-axis lines
        plot([-a(i)*cos(phi(i)), a(i)*cos(phi(i))], ...
             [-a(i)*sin(phi(i)), a(i)*sin(phi(i))], ...
             '-', 'Color',[c_opt 0.25], 'LineWidth',0.6);
        plot([b(i)*sin(phi(i)), -b(i)*sin(phi(i))], ...
             [-b(i)*cos(phi(i)),  b(i)*cos(phi(i))], ...
             '-', 'Color',[c_opt 0.25], 'LineWidth',0.6);

        axis equal;
        xlim([-cell_half cell_half]);
        ylim([-cell_half cell_half]);
        set(ax_m, 'XTick',[], 'YTick',[], 'XColor','none', ...
            'YColor','none', 'Color','none');
        hold off;

        % Link number label — add (proximal)/(distal) for 1 and 20
        if i == 1
            label_str = {'1','(Base)'};
        elseif i == 20
            label_str = {'20','(Tip)'};
        else
            label_str = sprintf('%d', i);
        end
        text(0.5, -0.06, label_str, 'Units','normalized', ...
             'FontSize',9, 'HorizontalAlignment','center', ...
             'VerticalAlignment','top', 'Color',[0.2 0.2 0.2], ...
             'FontWeight','bold');
    end

    % Row labels — use Unicode en-dash instead of \endash
    annotation('textbox', ...
        [x_offset-0.07, row_tops(1), 0.06, cell_size], ...
        'String', sprintf('Links\n1%s10', char(8211)), ...
        'FontSize',9, 'FontWeight','bold', 'Color',[0.33 0.33 0.33], ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'EdgeColor','none', 'Interpreter','none');
    annotation('textbox', ...
        [x_offset-0.07, row_tops(2), 0.06, cell_size], ...
        'String', sprintf('Links\n11%s20', char(8211)), ...
        'FontSize',9, 'FontWeight','bold', 'Color',[0.33 0.33 0.33], ...
        'HorizontalAlignment','center', 'VerticalAlignment','middle', ...
        'EdgeColor','none', 'Interpreter','none');

    % Legend
    ax_leg = axes('Position', [pl+0.05, bot_a-0.030, pw-0.1, 0.02]);
    hold on;
    h1 = fill(nan, nan, c_opt, 'FaceAlpha',0.20, 'EdgeColor',c_opt, ...
              'LineWidth',1.2);
    h2 = plot(nan, nan, '--', 'Color',c_cyl_rgb, 'LineWidth',0.8);
    legend([h1 h2], ...
        {'Optimized cross-section', ...
         sprintf('Cylindrical baseline (r = %.3f mm)', r_cyl)}, ...
        'FontSize',9, 'Orientation','horizontal', ...
        'EdgeColor',[0.87 0.87 0.87], 'Location','south');
    axis off; hold off;

    % ═══════════════════════════════════════════
    % Panel (b): Cross-sectional area
    % ═══════════════════════════════════════════
    ax2 = axes('Position', [pl bot_b pw h_bar]);
    hold on; box off;

    for i = 1:N
        bar(arc_pos(i), areas(i), 7, 'FaceColor',c_opt, 'FaceAlpha',0.7, ...
            'EdgeColor','w', 'LineWidth',0.5);
    end
    plot([3 210], [area_cyl area_cyl], '--', 'Color',c_cyl_rgb, 'LineWidth',1);
    text(208, area_cyl, sprintf('%.0f', area_cyl), 'FontSize',10, ...
         'Color',c_cyl_rgb, 'VerticalAlignment','middle', 'FontWeight','bold');

    xlim([3 210]);
    ylim_b = ylim; ylim([0 ylim_b(2)*1.08]);
    ylabel({'Area','(mm^2)'}, 'FontSize',12, 'FontWeight','bold', ...
           'Rotation',0, 'HorizontalAlignment','right', ...
           'VerticalAlignment','middle');
    set(ax2, 'XTick',[], 'XColor','none', 'TickDir','out');
    ax2.YAxis.FontSize = 11;
    ax2.YAxis.FontWeight = 'bold';

    text(-0.09, 1.0, '(b)', 'Units','normalized', 'FontSize',13, ...
         'FontWeight','bold', 'VerticalAlignment','top');
    hold off;

    % ═══════════════════════════════════════════
    % Panel (c): Aspect ratio
    % ═══════════════════════════════════════════
    ax3 = axes('Position', [pl bot_c pw h_bar]);
    hold on; box off;

    for i = 1:N
        bar(arc_pos(i), aspect_ratios(i), 7, 'FaceColor',c_purple, ...
            'FaceAlpha',0.6, 'EdgeColor','w', 'LineWidth',0.5);
    end
    plot([3 210], [1.0 1.0], '--', 'Color',c_cyl_rgb, 'LineWidth',1);
    text(208, 1.0, '1.0', 'FontSize',10, 'Color',c_cyl_rgb, ...
         'VerticalAlignment','middle', 'FontWeight','bold');

    xlim([3 210]);
    ylim_c = ylim; ylim([0 ylim_c(2)*1.08]);
    ylabel({'Aspect','ratio'}, 'FontSize',12, 'FontWeight','bold', ...
           'Rotation',0, 'HorizontalAlignment','right', ...
           'VerticalAlignment','middle');
    set(ax3, 'XTick',[], 'XColor','none', 'TickDir','out');
    ax3.YAxis.FontSize = 11;
    ax3.YAxis.FontWeight = 'bold';

    text(-0.09, 1.0, '(c)', 'Units','normalized', 'FontSize',13, ...
         'FontWeight','bold', 'VerticalAlignment','top');
    hold off;

    % ═══════════════════════════════════════════
    % Panel (d): Rotation angle
    % ═══════════════════════════════════════════
    ax4 = axes('Position', [pl bot_d pw h_bar]);
    hold on; box off;

    for i = 1:N
        bar(arc_pos(i), phi_deg(i), 7, 'FaceColor',c_green, ...
            'FaceAlpha',0.6, 'EdgeColor','w', 'LineWidth',0.5);
    end

    xlim([3 210]);
    ylim_d = ylim; ylim([0 max(ylim_d(2)*1.1, 5)]);
    ylabel({'Rotation','\phi (°)'}, 'FontSize',12, 'FontWeight','bold', ...
           'Rotation',0, 'HorizontalAlignment','right', ...
           'VerticalAlignment','middle');
    xlabel('Link number', 'FontSize',12, 'FontWeight','bold');
    set(ax4, 'XTick',arc_pos, 'TickDir','out');
    set(ax4, 'XTickLabel', arrayfun(@(x) sprintf('%d',x), 1:N, ...
        'UniformOutput',false));
    ax4.XAxis.FontSize = 10;
    ax4.XAxis.FontWeight = 'bold';
    ax4.YAxis.FontSize = 11;
    ax4.YAxis.FontWeight = 'bold';

    text(-0.09, 1.0, '(d)', 'Units','normalized', 'FontSize',13, ...
         'FontWeight','bold', 'VerticalAlignment','top');
    hold off;

end