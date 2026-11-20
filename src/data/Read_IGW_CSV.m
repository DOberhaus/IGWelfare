function T = Read_IGW_CSV(filepath)
%% ZERO-DEPENDENCY TABULAR CSV READER FOR MATLAB AND GNU OCTAVE
% File: src/data/Read_IGW_CSV.m
% Reads a header-row CSV (ignoring blank lines and '#' comment lines) into a struct:
%   - T.Headers  : {1 x N_cols} cell array of column names
%   - T.N_Rows   : scalar row count
%   - T.<ColName>: [N_rows x 1] double column vector (if all entries are numeric)
%                  OR {N_rows x 1} cell array of char (if text/ID column)

if exist(filepath, 'file') ~= 2
    error('IGWelfare:MissingCSV', 'CSV file not found: %s', filepath);
end

raw_text = fileread(filepath);
lines    = regexp(raw_text, '\r\n|\n|\r', 'split');

valid_lines = {};
for i = 1:numel(lines)
    ln_trim = strtrim(lines{i});
    if isempty(ln_trim) || ln_trim(1) == '#'
        continue;
    end
    valid_lines{end+1} = ln_trim; %#ok<AGROW>
end

if isempty(valid_lines)
    error('IGWelfare:EmptyCSV', 'CSV file has no header or data rows: %s', filepath);
end

raw_headers = parse_csv_line(valid_lines{1});
N_cols      = numel(raw_headers);
N_rows      = numel(valid_lines) - 1;

headers = cell(1, N_cols);
for c = 1:N_cols
    headers{c} = regexprep(strtrim(raw_headers{c}), '[^a-zA-Z0-9_]', '_');
end

cell_grid = cell(N_rows, N_cols);
for r = 1:N_rows
    row_cells = parse_csv_line(valid_lines{r + 1});
    if numel(row_cells) ~= N_cols
        error('IGWelfare:CSVMismatch', ...
            '%s row %d has %d columns, expected %d (%s).', ...
            filepath, r + 1, numel(row_cells), N_cols, valid_lines{r + 1});
    end
    cell_grid(r, :) = row_cells;
end

T         = struct();
T.Headers = headers;
T.N_Rows  = N_rows;

for c = 1:N_cols
    col_cells = cell_grid(:, c);
    col_nums  = zeros(N_rows, 1);
    is_num    = true;
    for r = 1:N_rows
        s = strtrim(col_cells{r});
        if (length(s) >= 2) && ((s(1) == '"' && s(end) == '"') || (s(1) == '''' && s(end) == ''''))
            col_cells{r} = s(2:end-1);
            is_num = false;
        else
            v = str2double(s);
            if isnan(v) && ~strcmpi(s, 'NaN')
                col_cells{r} = s;
                is_num = false;
            else
                col_nums(r) = v;
                col_cells{r} = s;
            end
        end
    end
    if is_num && N_rows > 0
        T.(headers{c}) = col_nums;
    else
        T.(headers{c}) = col_cells;
    end
end
end

function cells = parse_csv_line(line_str)
cells = {};
cur   = '';
in_q  = false;
for i = 1:length(line_str)
    ch = line_str(i);
    if ch == '"'
        in_q = ~in_q;
        cur  = [cur, ch]; %#ok<AGROW>
    elseif ch == ',' && ~in_q
        cells{end+1} = strtrim(cur); %#ok<AGROW>
        cur = '';
    else
        cur = [cur, ch]; %#ok<AGROW>
    end
end
cells{end+1} = strtrim(cur);
end
