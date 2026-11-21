function Meta = igw_smart_incanvas_legend(ax, Items, Opts)
%% DETERMINISTIC IN-CANVAS LEGEND (PURE PAPER-POINT SIZING, ZERO PIXEL-EXTENT BLOWUP)
% File: src/utils/igw_smart_incanvas_legend.m

if nargin < 3 || isempty(Opts), Opts = struct(); end
fs          = get_opt(Opts, 'FontSize',    6.9);
n_cols      = get_opt(Opts, 'NumColumns',  1);
halo_mult   = get_opt(Opts, 'HaloMult',    5.0);
extra_m_pt  = get_opt(Opts, 'MarginPt',    0.0);
max_interf  = get_opt(Opts, 'MaxInterf',   0.10);
auto_expand = get_opt(Opts, 'AutoExpandY', false);
pref_locs   = get_opt(Opts, 'PreferLocs',  {'northeast', 'northwest', 'southeast', 'southwest'});
def_font    = get(0, 'DefaultAxesFontName');

fig      = ancestor(ax, 'figure');
ax_pos_n = get(ax, 'Position');

% Exact PaperPosition dimensions in typographic points (72 pt/in):
[fig_w_pt, fig_h_pt] = get_fig_paper_pts(fig);
ax_w_pt  = max(120.0, ax_pos_n(3) * fig_w_pt);
ax_h_pt  = max(90.0,  ax_pos_n(4) * fig_h_pt);

n_items  = size(Items, 1);
n_cols   = max(1, min(n_cols, n_items));
n_rows   = ceil(n_items / n_cols);

% Crisp, tight-fitting regular-weight legend geometry in points:
row_h_pt   = fs * 1.46;
swatch_pt  = 15.0;
gap_sw_pt  = 4.8;
col_pad_pt = 11.0;
pad_x_pt   = max(6.8, fs * 1.00);
pad_y_pt   = max(5.2, fs * 0.78);

% Whisker-tip rule: outer clearance from inward tick whisker-tips >= inner text-to-box padding:
tick_len_p = get(ax, 'TickLength');
whisker_pt = 0.0;
if ~strcmpi(get(ax, 'TickDir'), 'out')
    whisker_pt = tick_len_p(1) * max(ax_w_pt, ax_h_pt);
end
outer_x_pt = whisker_pt + pad_x_pt + extra_m_pt;
outer_y_pt = whisker_pt + pad_y_pt + extra_m_pt;

% Pure typographic-point glyph width per column (immune to Octave pixel-Extent bugs!):
col_w_pt = zeros(1, n_cols);
for c = 1:n_cols
    idx_c = ((c-1)*n_rows + 1) : min(n_items, c*n_rows);
    max_tw_pt = 0.0;
    for k = idx_c
        max_tw_pt = max(max_tw_pt, measure_regular_str_pt(Items{k, 5}, fs));
    end
    col_w_pt(c) = swatch_pt + gap_sw_pt + max_tw_pt;
end

box_w_pt = min(ax_w_pt - 2.0*outer_x_pt, sum(col_w_pt) + (n_cols - 1)*col_pad_pt + 2.0*pad_x_pt);
box_h_pt = min(ax_h_pt * 0.45, n_rows * row_h_pt + 2.0*pad_y_pt);

bw_u = box_w_pt / ax_w_pt;
bh_u = box_h_pt / ax_h_pt;
mx_u = outer_x_pt / ax_w_pt;
my_u = outer_y_pt / ax_h_pt;

max_feat_pt = 2.5;
for k = 1:n_items
    lw_k = Items{k, 3}; mk_k = Items{k, 4};
    if ~isempty(mk_k) && ~strcmp(mk_k, 'none')
        max_feat_pt = max(max_feat_pt, 5.5);
    else
        max_feat_pt = max(max_feat_pt, lw_k);
    end
end
halo_pt = halo_mult * max_feat_pt;
hx_u    = halo_pt / ax_w_pt;
hy_u    = halo_pt / ax_h_pt;

% Collect data samples from `ax` AND its yyaxis right twin if present:
[pts_x, pts_y, is_bar_only] = collect_axes_data_samples(ax);
xl = get(ax, 'XLim');
yl = get(ax, 'YLim');

best_loc   = pref_locs{1};
best_score = inf;
best_rect  = corner_rect_unit(best_loc, bw_u, bh_u, mx_u, my_u);
for c = 1:numel(pref_locs)
    loc = pref_locs{c};
    r_u = corner_rect_unit(loc, bw_u, bh_u, mx_u, my_u);
    inf_frac = compute_interference_frac(pts_x, pts_y, xl, yl, r_u, hx_u, hy_u);
    score = inf_frac + (c - 1) * 0.002;
    if score < best_score
        best_score = score; best_loc = loc; best_rect = r_u;
    end
end

% Optional polite floor above a horizontal reference line (e.g. Y = 0 in Panel D):
if isfield(Opts, 'YMinDataFloor') && ~isempty(Opts.YMinDataFloor)
    y_fl_u = (Opts.YMinDataFloor - yl(1)) / max(1e-12, yl(2) - yl(1));
    if best_rect(2) < y_fl_u
        best_rect(2) = min(1.0 - my_u - bh_u, y_fl_u);
    end
end

% Optional explicit data-space anchor (e.g., XLeft > 0 OBEGAL line & YCenter = 75):
if isfield(Opts, 'CustomDataAnchor') && isstruct(Opts.CustomDataAnchor)
    anc = Opts.CustomDataAnchor;
    ux0 = (anc.XLeft - xl(1)) / max(1e-12, xl(2) - xl(1));
    uyc = (anc.YCenter - yl(1)) / max(1e-12, yl(2) - yl(1));
    ux0 = max(mx_u, min(1.0 - mx_u - bw_u, ux0));
    uy0 = max(my_u, min(1.0 - my_u - bh_u, uyc - 0.5 * bh_u));
    best_rect = [ux0, uy0, bw_u, bh_u];
    best_loc  = 'custom_data';
end

actual_inf = compute_interference_frac(pts_x, pts_y, xl, yl, best_rect, hx_u, hy_u);
if auto_expand && actual_inf > max_interf && ~isempty(pts_y)
    use_top = ~strncmpi(best_loc, 'south', 5) || is_bar_only;
    in_x  = pts_x >= xl(1) & pts_x <= xl(2);
    span0 = yl(2) - yl(1);
    x_lo  = xl(1) + max(0.0, best_rect(1) - hx_u) * (xl(2) - xl(1));
    x_hi  = xl(1) + min(1.0, best_rect(1) + best_rect(3) + hx_u) * (xl(2) - xl(1));
    m_sp  = in_x & (pts_x >= x_lo) & (pts_x <= x_hi);
    if use_top && any(m_sp)
        y_peak = max(pts_y(m_sp));
        avail  = max(0.55, best_rect(2) - hy_u);
        yl(2)  = min(yl(2) + 0.22 * span0, max(yl(2), yl(1) + (y_peak - yl(1)) / avail));
        set(ax, 'YLim', yl);
    elseif ~use_top && any(m_sp)
        y_tr   = min(pts_y(m_sp));
        top_u  = min(0.45, best_rect(2) + best_rect(4) + hy_u);
        yl(1)  = max(yl(1) - 0.22 * span0, min(yl(1), yl(2) - (yl(2) - y_tr) / (1.0 - top_u)));
        set(ax, 'YLim', yl);
    end
    actual_inf = compute_interference_frac(pts_x, pts_y, xl, yl, best_rect, hx_u, hy_u);
end

% If `ax` has a yyaxis right overlay, ensure the transparent right axes sits above opaque `ax`
% BEFORE creating `axL` (so both right curves AND `axL` remain 100% visible!):
pair = getappdata(ax, 'vfi_yyaxis_pair');
if ~isempty(pair) && isfield(pair, 'right') && ishandle(pair.right)
    set(pair.right, 'Color', 'none', 'Position', ax_pos_n);
    try, uistack(pair.right, 'top'); catch, end
end

lgd_fig_pos = [ ...
    ax_pos_n(1) + best_rect(1) * ax_pos_n(3), ...
    ax_pos_n(2) + best_rect(2) * ax_pos_n(4), ...
    best_rect(3) * ax_pos_n(3), ...
    best_rect(4) * ax_pos_n(4)];

axL = axes('Parent', fig, 'Position', lgd_fig_pos, ...
    'XLim', [0, box_w_pt], 'YLim', [0, box_h_pt], ...
    'Color', 'none', 'XTick', [], 'YTick', [], 'Box', 'off', ...
    'Visible', 'off', 'HitTest', 'off', 'Tag', 'IGW_SmartLegend');
hold(axL, 'on');

patch(axL, [0, box_w_pt, box_w_pt, 0], [0, 0, box_h_pt, box_h_pt], [1.0, 1.0, 1.0], ...
    'FaceAlpha', 0.93, 'EdgeColor', [0.58, 0.62, 0.68], 'LineWidth', 0.75);

x_col_offsets = [pad_x_pt, pad_x_pt + cumsum(col_w_pt(1:end-1) + col_pad_pt)];
for idx = 1:n_items
    c_idx = ceil(idx / n_rows);
    r_idx = idx - (c_idx - 1) * n_rows;
    x0    = x_col_offsets(c_idx);
    yc    = box_h_pt - pad_y_pt - (r_idx - 0.5) * row_h_pt;

    kind  = Items{idx, 1}; col = Items{idx, 2};
    lw_i  = Items{idx, 3}; mk_i = Items{idx, 4}; lbl_i = Items{idx, 5};

    if strcmpi(kind, 'bar')
        bh_s = row_h_pt * 0.52;
        patch(axL, [x0, x0 + swatch_pt, x0 + swatch_pt, x0], ...
            [yc - 0.5*bh_s, yc - 0.5*bh_s, yc + 0.5*bh_s, yc + 0.5*bh_s], col, ...
            'EdgeColor', col * 0.65, 'LineWidth', 0.7);
    else
        ls = kind; if strcmpi(ls, 'line'), ls = '-'; end
        plot(axL, [x0, x0 + swatch_pt], [yc, yc], 'LineStyle', ls, 'Color', col, 'LineWidth', min(2.4, lw_i));
        if ~isempty(mk_i) && ~strcmpi(mk_i, 'none')
            plot(axL, x0 + 0.5*swatch_pt, yc, 'Marker', mk_i, 'MarkerSize', 4.6, ...
                'MarkerFaceColor', col, 'MarkerEdgeColor', col, 'LineStyle', 'none');
        end
    end

    text(axL, x0 + swatch_pt + gap_sw_pt, yc, lbl_i, ...
        'Interpreter', 'none', 'FontName', def_font, 'FontSize', fs, 'FontWeight', 'normal', ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left', 'Color', [0.14, 0.17, 0.22]);
end

set(ax, 'Position', ax_pos_n);

Meta = struct('LegendAxes', axL, 'Location', best_loc, 'UnitRectInAxes', best_rect, ...
    'FigNormPos', lgd_fig_pos, 'ParentAxesPos', ax_pos_n, 'InterferenceFrac', actual_inf, 'HaloPt', halo_pt);
end

function [w_pt, h_pt] = get_fig_paper_pts(fig)
    pu = get(fig, 'PaperUnits');
    pp = get(fig, 'PaperPosition');
    switch lower(pu)
        case 'inches',      scale = 72.0;
        case 'centimeters', scale = 72.0 / 2.54;
        case 'points',      scale = 1.0;
        otherwise
            scr_dpi = 127.5;
            try, scr_dpi = max(72.0, get(0, 'ScreenPixelsPerInch')); catch, end
            u0 = get(fig, 'Units'); set(fig, 'Units', 'pixels');
            ppx = get(fig, 'Position'); set(fig, 'Units', u0);
            w_pt = ppx(3) * 72.0 / scr_dpi;
            h_pt = ppx(4) * 72.0 / scr_dpi;
            return;
    end
    w_pt = pp(3) * scale;
    h_pt = pp(4) * scale;
end

function w_pt = measure_regular_str_pt(s, fs_pt)
    w_em = 0.0;
    for ii = 1:numel(s)
        ch = s(ii);
        if any(ch == 'MW@%QGO0D'), w_em = w_em + 0.74;
        elseif (ch >= 'A' && ch <= 'Z') || any(ch == '+<>=~'), w_em = w_em + 0.64;
        elseif any(ch == 'il1.,:;|!()[]''` '), w_em = w_em + 0.32;
        elseif double(ch) > 127, w_em = w_em + 0.76;
        else, w_em = w_em + 0.55; end
    end
    w_pt = w_em * fs_pt + 4.0; % +4pt comfortable right cushion
end

function val = get_opt(S, f, def)
    if isstruct(S) && isfield(S, f) && ~isempty(S.(f)), val = S.(f); else, val = def; end
end

function r = corner_rect_unit(loc, bw, bh, mx, my)
    switch lower(loc)
        case 'northwest', r = [mx, 1.0 - my - bh, bw, bh];
        case 'northeast', r = [1.0 - mx - bw, 1.0 - my - bh, bw, bh];
        case 'north',     r = [0.5 * (1.0 - bw), 1.0 - my - bh, bw, bh];
        case 'southwest', r = [mx, my, bw, bh];
        case 'southeast', r = [1.0 - mx - bw, my, bw, bh];
        otherwise,        r = [1.0 - mx - bw, 1.0 - my - bh, bw, bh];
    end
end

function [px, py, is_bar_only] = collect_axes_data_samples(ax)
    px = []; py = [];
    ax_list = ax;
    xl0 = get(ax, 'XLim'); yl0 = get(ax, 'YLim');
    pair = getappdata(ax, 'vfi_yyaxis_pair');
    if ~isempty(pair) && isfield(pair, 'right') && ishandle(pair.right)
        ax_list = [pair.left, pair.right];
    end
    n_lines = 0; n_bars = 0;
    for a_i = 1:numel(ax_list)
        ax_cur = ax_list(a_i);
        yl_c   = get(ax_cur, 'YLim');
        ch     = get(ax_cur, 'Children');
        for k = 1:numel(ch)
            tp = get(ch(k), 'Type');
            if strcmpi(get(ch(k), 'HandleVisibility'), 'off'), continue; end
            if strcmpi(tp, 'line')
                xd = get(ch(k), 'XData'); yd = get(ch(k), 'YData');
                if numel(xd) >= 2
                    n_lines = n_lines + 1;
                    idx_s = linspace(1, numel(xd), 120);
                    xi = reshape(interp1(1:numel(xd), xd(:), idx_s, 'linear'), [], 1);
                    yi = reshape(interp1(1:numel(yd), yd(:), idx_s, 'linear'), [], 1);
                    % Map right-axis Y into primary `ax` YLim so normalized [0..1] occupancy is exact:
                    yi_mapped = yl0(1) + ((yi - yl_c(1)) / max(1e-12, yl_c(2) - yl_c(1))) * (yl0(2) - yl0(1));
                    px = [px; xi]; %#ok<AGROW>
                    py = [py; yi_mapped]; %#ok<AGROW>
                end
            elseif strcmpi(tp, 'bar') || strcmpi(tp, 'hggroup') || strcmpi(tp, 'patch')
                try
                    xd = get(ch(k), 'XData'); yd = get(ch(k), 'YData');
                    if ~isempty(xd) && ~isempty(yd)
                        n_bars = n_bars + 1;
                        % Account for grouped bar cluster horizontal spread (+/- 0.34 around group center):
                        x_flat = xd(:); y_flat = yd(:);
                        for b = 1:numel(x_flat)
                            ys = linspace(0, y_flat(b), 12)';
                            for dx_b = [-0.28, 0.0, +0.28]
                                px = [px; repmat(x_flat(b) + dx_b, 12, 1)]; %#ok<AGROW>
                                py = [py; ys]; %#ok<AGROW>
                            end
                        end
                    end
                catch
                end
            end
        end
    end
    is_bar_only = (n_bars > 0) && (n_lines == 0);
end

function frac = compute_interference_frac(px, py, xl, yl, rect_u, hx_u, hy_u)
    if isempty(px), frac = 0.0; return; end
    in_vis = (px >= xl(1)) & (px <= xl(2)) & (py >= yl(1)) & (py <= yl(2));
    if ~any(in_vis), frac = 0.0; return; end
    ux = (px(in_vis) - xl(1)) / max(1e-12, xl(2) - xl(1));
    uy = (py(in_vis) - yl(1)) / max(1e-12, yl(2) - yl(1));
    hit = (ux >= rect_u(1) - hx_u) & (ux <= rect_u(1) + rect_u(3) + hx_u) & ...
          (uy >= rect_u(2) - hy_u) & (uy <= rect_u(2) + rect_u(4) + hy_u);
    frac = sum(hit) / max(1, numel(ux));
end
