function ax = vfi_active_ax(ax_in)
if nargin >= 1 && ~isempty(ax_in)
    ax = ax_in;
    return;
end
cf = get(0, 'CurrentFigure');
if ~isempty(cf) && ishandle(cf)
    ax = get(cf, 'CurrentAxes');
    if isempty(ax) || ~ishandle(ax)
        ax = gca;
    end
    return;
end
% Headless fallback when figures have Visible='off' so CurrentFigure is empty
all_ax = findall(0, 'Type', 'axes');
if ~isempty(all_ax)
    ax = all_ax(1);
else
    ax = gca;
end
end
