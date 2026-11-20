function S = Read_IGW_YAML(filepath)
%% ZERO-DEPENDENCY SUBSET YAML PARSER FOR MATLAB AND GNU OCTAVE
% File: src/data/Read_IGW_YAML.m
% Parses clean configuration YAML files supporting:
%   - Top-level key: value pairs (numbers, booleans, strings, inline [a, b, c] arrays)
%   - 1-level nested maps (Section:\n  key: value)
%   - Lists of maps (Items:\n  - Key1: val1\n    SubList:\n      - SubKey: val2)
%   - Full-line and inline '#' comments (outside quoted strings)

if exist(filepath, 'file') ~= 2
    error('IGWelfare:MissingYAML', 'YAML file not found: %s', filepath);
end

raw_text = fileread(filepath);
lines    = regexp(raw_text, '\r\n|\n|\r', 'split');

S            = struct();
curr_sec     = '';
curr_list    = '';
list_idx     = 0;
curr_sublist = '';
sublist_idx  = 0;

for ln = 1:numel(lines)
    line_clean = strip_yaml_comment(lines{ln});
    if isempty(strtrim(line_clean))
        continue;
    end

    indent = length(line_clean) - length(strtrim_left(line_clean));
    trimmed = strtrim(line_clean);

    % Top-level key or section (indent == 0)
    if indent == 0
        curr_sec     = '';
        curr_list    = '';
        curr_sublist = '';
        [k, v_str, has_val] = split_kv(trimmed, filepath, ln);
        f_k = make_valid_field(k);
        if ~has_val
            curr_sec = f_k;
            if ~isfield(S, curr_sec), S.(curr_sec) = struct(); end
        else
            S.(f_k) = parse_yaml_scalar_or_vec(v_str);
        end

    % Indent level 1 (indent >= 2 and < 6): section entry OR list item '- Key: Val'
    elseif indent < 6 && strncmp(trimmed, '- ', 2)
        if isempty(curr_sec)
            error('IGWelfare:YAMLParseError', '%s:%d unexpected list item at top level.', filepath, ln);
        end
        if isempty(curr_list)
            curr_list = curr_sec;
            S.(curr_list) = {};
            list_idx = 0;
        end
        curr_sublist = '';
        list_idx = list_idx + 1;
        item_body = strtrim(trimmed(3:end));
        item_struct = struct();
        if ~isempty(item_body)
            [k, v_str, has_val] = split_kv(item_body, filepath, ln);
            if has_val
                item_struct.(make_valid_field(k)) = parse_yaml_scalar_or_vec(v_str);
            end
        end
        S.(curr_list){list_idx} = item_struct;

    elseif indent < 6 && ~isempty(curr_list)
        % Continuation field of current list item (e.g. indent == 4)
        [k, v_str, has_val] = split_kv(trimmed, filepath, ln);
        f_k = make_valid_field(k);
        if ~has_val
            curr_sublist = f_k;
            S.(curr_list){list_idx}.(curr_sublist) = {};
            sublist_idx = 0;
        else
            curr_sublist = '';
            S.(curr_list){list_idx}.(f_k) = parse_yaml_scalar_or_vec(v_str);
        end

    elseif indent < 6 && ~isempty(curr_sec)
        % Standard 1-level nested map key: value
        [k, v_str, has_val] = split_kv(trimmed, filepath, ln);
        f_k = make_valid_field(k);
        if has_val
            S.(curr_sec).(f_k) = parse_yaml_scalar_or_vec(v_str);
        end

    % Indent level >= 6: nested sublist inside a list item (e.g. Gate Conditions)
    elseif indent >= 6 && ~isempty(curr_list) && ~isempty(curr_sublist)
        if strncmp(trimmed, '- ', 2)
            sublist_idx = sublist_idx + 1;
            sub_body = strtrim(trimmed(3:end));
            sub_struct = struct();
            if ~isempty(sub_body)
                [k, v_str, has_val] = split_kv(sub_body, filepath, ln);
                if has_val
                    sub_struct.(make_valid_field(k)) = parse_yaml_scalar_or_vec(v_str);
                end
            end
            S.(curr_list){list_idx}.(curr_sublist){sublist_idx} = sub_struct;
        else
            [k, v_str, has_val] = split_kv(trimmed, filepath, ln);
            if has_val && sublist_idx >= 1
                S.(curr_list){list_idx}.(curr_sublist){sublist_idx}.(make_valid_field(k)) = parse_yaml_scalar_or_vec(v_str);
            end
        end
    end
end
end

%% --- LOCAL HELPERS ---
function out = strip_yaml_comment(in_str)
in_sq = false;
in_dq = false;
out   = in_str;
for i = 1:length(in_str)
    ch = in_str(i);
    if ch == '''' && ~in_dq
        in_sq = ~in_sq;
    elseif ch == '"' && ~in_sq
        in_dq = ~in_dq;
    elseif ch == '#' && ~in_sq && ~in_dq
        out = in_str(1:i-1);
        return;
    end
end
end

function s = strtrim_left(s)
idx = find(~isspace(s), 1, 'first');
if isempty(idx), s = ''; else, s = s(idx:end); end
end

function [k, v_str, has_val] = split_kv(trimmed, filepath, ln)
colon_idx = find(trimmed == ':', 1, 'first');
if isempty(colon_idx)
    error('IGWelfare:YAMLParseError', '%s:%d missing colon in line: %s', filepath, ln, trimmed);
end
k       = strtrim(trimmed(1:colon_idx-1));
v_str   = strtrim(trimmed(colon_idx+1:end));
has_val = ~isempty(v_str);
end

function f = make_valid_field(k)
f = regexprep(k, '[^a-zA-Z0-9_]', '_');
end

function val = parse_yaml_scalar_or_vec(v_str)
if isempty(v_str)
    val = '';
    return;
end
if (v_str(1) == '''' && v_str(end) == '''') || (v_str(1) == '"' && v_str(end) == '"')
    val = v_str(2:end-1);
    return;
end
if v_str(1) == '[' && v_str(end) == ']'
    inner = strtrim(v_str(2:end-1));
    if isempty(inner)
        val = [];
        return;
    end
    parts = strsplit(inner, ',');
    nums  = zeros(1, numel(parts));
    all_num = true;
    str_cell = cell(1, numel(parts));
    for i = 1:numel(parts)
        p_i = strtrim(parts{i});
        if (length(p_i) >= 2) && ((p_i(1) == '''' && p_i(end) == '''') || (p_i(1) == '"' && p_i(end) == '"'))
            all_num = false;
            str_cell{i} = p_i(2:end-1);
        else
            n_i = str2double(p_i);
            if isnan(n_i)
                all_num = false;
                str_cell{i} = p_i;
            else
                nums(i) = n_i;
                str_cell{i} = p_i;
            end
        end
    end
    if all_num
        val = nums;
    else
        val = str_cell;
    end
    return;
end
if any(strcmpi(v_str, {'true', 'yes'}))
    val = true;
    return;
elseif any(strcmpi(v_str, {'false', 'no'}))
    val = false;
    return;
end
num_val = str2double(v_str);
if ~isnan(num_val)
    val = num_val;
else
    val = v_str;
end
end
