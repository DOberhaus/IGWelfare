%% IGWELFARE REPOSITORY-LOCAL MATLAB STARTUP (startup.m)
% Automatically executed whenever MATLAB starts in (or via -sd) the IGWelfare root directory.

igw_st_dir = fileparts(mfilename('fullpath'));
if isempty(igw_st_dir)
    igw_st_dir = pwd;
end
if exist(fullfile(igw_st_dir, 'setup_igw_paths.m'), 'file') == 2
    addpath(igw_st_dir);
    setup_igw_paths(false);
end
clear igw_st_dir;
