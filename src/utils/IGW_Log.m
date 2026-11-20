function IGW_Log(id, fmt, varargin)
%% RUN-LOG WRITER FOR IGW:* SIGNALS (WARNING + igw_run.log LINE)
% File: src/utils/IGW_Log.m
% Appends ONE line  <ISO8601 local time> <id> <message>  to igw_run.log in the current
% directory (or getappdata(0, 'IGW_LOG_DIR') when explicitly set) and issues warning(id, ...).

msg = sprintf(fmt, varargin{:});

log_dir = getappdata(0, 'IGW_LOG_DIR');
if isempty(log_dir) || exist(log_dir, 'dir') == 0
    log_dir = pwd;
end

try
    fid = fopen(fullfile(log_dir, 'igw_run.log'), 'a');
    if fid > 0
        line = strrep(strrep(msg, char(13), ''), char(10), ' | ');
        fprintf(fid, '%s %s %s\n', datestr(now, 'yyyy-mm-ddTHH:MM:SS'), id, line);
        fclose(fid);
    end
catch
    % logging must never break a run: fall through to the warning alone
end

warning(id, '%s', msg);

end
