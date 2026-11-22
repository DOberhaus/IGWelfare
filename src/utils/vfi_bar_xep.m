function x_pts = vfi_bar_xep(b_h, k)
%VFI_BAR_XEP Return horizontal center coordinates of grouped bar series k (MATLAB & Octave).
if iscell(b_h), bh = b_h{k}; else, bh = b_h(k); end
if isprop(bh, 'XEndPoints') && ~isempty(bh.XEndPoints)
    x_pts = reshape(bh.XEndPoints, 1, []);
    return;
end
if isprop(bh, 'XData') && isprop(bh, 'XOffset')
    x_pts = reshape(bh.XData, 1, []) + double(bh.XOffset);
    return;
end
p = findobj(bh, 'Type', 'patch');
if isempty(p), p = bh; end
xd = get(p(1), 'XData');
if size(xd, 1) == 4
    x_pts = mean(xd, 1);
else
    x_pts = mean(xd(:))';
end
end
