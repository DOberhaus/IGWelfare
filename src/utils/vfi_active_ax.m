function ax = vfi_active_ax(ax_in)
%% UNIFIED HEADLESS & DUAL-AXIS (YYAXIS) HANDLE RESOLVER (MATLAB & GNU OCTAVE)
% File: src/utils/vfi_active_ax.m
% Combines two essential cross-platform behaviors in one authoritative helper:
%   1. When ax_in is empty/omitted under Visible='off' (where CurrentFigure is empty),
%      resolves the active axes via CurrentFigure -> findall(0, 'Type', 'axes') -> gca.
%   2. When ax_in is managed by VFIToolkit-octave's yyaxis() twin-axes shim
%      (appdata 'vfi_yyaxis_pair'), returns the currently active left or right peer axis.

if nargin < 1 || isempty(ax_in)
    cf = get(0, 'CurrentFigure');
    if ~isempty(cf) && ishandle(cf)
        ax = get(cf, 'CurrentAxes');
        if isempty(ax) || ~ishandle(ax)
            ax = gca;
        end
    else
        all_ax = findall(0, 'Type', 'axes');
        if ~isempty(all_ax)
            ax = all_ax(1);
        else
            ax = gca;
        end
    end
    ax_in = ax;
end

if isscalar(ax_in) && ishandle(ax_in) && isappdata(ax_in, 'vfi_yyaxis_pair')
    pair = getappdata(ax_in, 'vfi_yyaxis_pair');
    if isstruct(pair) && isfield(pair, 'right') && isfield(pair, 'left')
        fig_anc = ancestor(ax_in, 'figure');
        if ~isempty(fig_anc) && ishandle(fig_anc)
            cur = get(fig_anc, 'CurrentAxes');
            if isequal(cur, pair.right)
                ax = pair.right;
                return;
            end
        end
        ax = pair.left;
        return;
    end
end

ax = ax_in;
end
