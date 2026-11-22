function y_pts = vfi_bar_yep(b_h, k)
%VFI_BAR_YEP Return signed top/tip coordinates of grouped bar series k (MATLAB & Octave).
if iscell(b_h), bh = b_h{k}; else, bh = b_h(k); end
if isprop(bh, 'YEndPoints') && ~isempty(bh.YEndPoints)
    y_pts = reshape(bh.YEndPoints, 1, []);
    return;
end
if isprop(bh, 'YData') && ~isempty(bh.YData)
    y_pts = reshape(bh.YData, 1, []);
    return;
end
p = findobj(bh, 'Type', 'patch');
if isempty(p), p = bh; end
yd = get(p(1), 'YData');
if size(yd, 1) == 4
    [~, r_idx] = max(abs(yd), [], 1);
    y_pts = yd(sub2ind(size(yd), r_idx, 1:size(yd, 2)));
else
    [~, m_i] = max(abs(yd(:)));
    y_pts = yd(m_i);
end
end
