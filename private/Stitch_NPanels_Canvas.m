function [img_Merged, fig_pos] = Stitch_NPanels_Canvas(Panel_Imgs, Merge_Orientation)
N_p = numel(Panel_Imgs);
hs  = cellfun(@(x) size(x, 1), Panel_Imgs);
ws  = cellfun(@(x) size(x, 2), Panel_Imgs);

if strcmpi(Merge_Orientation, 'Vertical')
    W_max    = max(ws);
    pad_L    = 65; pad_R = 95;
    W_canvas = W_max + pad_L + pad_R;

    top_pad  = uint8(255 * ones(90, W_canvas, 3));
    bot_pad  = uint8(255 * ones(90, W_canvas, 3));
    gap_pre  = uint8(255 * ones(80, W_canvas, 3));
    div_line = uint8(220 * ones(4,  W_canvas, 3));
    gap_post = uint8(255 * ones(90, W_canvas, 3));

    blocks = {top_pad};
    for p = 1:N_p
        img_p = uint8(255 * ones(hs(p), W_canvas, 3));
        img_p(:, (pad_L+1):(pad_L+ws(p)), :) = Panel_Imgs{p};
        blocks{end+1} = img_p; %#ok<AGROW>
        if p < N_p
            blocks{end+1} = gap_pre;  %#ok<AGROW>
            blocks{end+1} = div_line; %#ok<AGROW>
            blocks{end+1} = gap_post; %#ok<AGROW>
        end
    end
    blocks{end+1} = bot_pad;
    img_Merged    = vertcat(blocks{:});
    fig_pos       = [80, 20, 1320, min(1150, 560 * N_p)];
else
    H_max    = max(hs);
    pad_T    = 90; pad_B = 90;
    H_canvas = H_max + pad_T + pad_B;
    left_pad = uint8(255 * ones(H_canvas, 65, 3));
    mid_gap  = uint8(255 * ones(H_canvas, 120, 3));
    right_pad= uint8(255 * ones(H_canvas, 95, 3));

    blocks = {left_pad};
    for p = 1:N_p
        img_p = uint8(255 * ones(H_canvas, ws(p), 3));
        img_p((pad_T+1):(pad_T+hs(p)), :, :) = Panel_Imgs{p};
        blocks{end+1} = img_p; %#ok<AGROW>
        if p < N_p
            blocks{end+1} = mid_gap; %#ok<AGROW>
        end
    end
    blocks{end+1} = right_pad;
    img_Merged    = horzcat(blocks{:});
    fig_pos       = [20, 80, min(1920, 920 * N_p), 740];
end


end
