function OutputDir = Resolve_IGW_OutputDir(ExplicitDir, Profile_ID)
%% CANONICAL PROFILE-SCOPED OUTPUT DIRECTORY RESOLVER
% File: src/utils/Resolve_IGW_OutputDir.m
% Priority order:
%   1. ExplicitDir passed directly by caller (unless empty or legacy placeholder)
%   2. Base workspace 'OutputDir' variable (when orchestrated inside a suite script)
%   3. Root appdata 'IGW_OUTPUT_DIR'
%   4. Clean profile-scoped '<igw_root>/output/<Profile_ID>'

if nargin < 1, ExplicitDir = ''; end
if nargin < 2 || isempty(Profile_ID), Profile_ID = 'NZ_Dunedin1972'; end

igw_root = getappdata(0, 'IGW_ROOT_DIR');
if isempty(igw_root)
    here = fileparts(mfilename('fullpath'));
    igw_root = fileparts(fileparts(here));
end

if ~isempty(ExplicitDir) && ~strcmp(ExplicitDir, 'Output_NZ_4Region_Intergen')
    OutputDir = char(ExplicitDir);
elseif evalin('base', 'exist(''OutputDir'', ''var'')') && ~isempty(evalin('base', 'OutputDir'))
    OutputDir = evalin('base', 'OutputDir');
elseif ~isempty(getappdata(0, 'IGW_OUTPUT_DIR'))
    OutputDir = getappdata(0, 'IGW_OUTPUT_DIR');
else
    OutputDir = fullfile(igw_root, 'output', char(Profile_ID));
end

if ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end
end
