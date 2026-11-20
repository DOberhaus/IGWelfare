function OutputDir = Resolve_IGW_OutputDir(ExplicitDir, Profile_ID)
%% CANONICAL PROFILE-SCOPED OUTPUT DIRECTORY RESOLVER
% File: src/utils/Resolve_IGW_OutputDir.m

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
elseif exist(fullfile(pwd, 'Output_NZ_4Region_Intergen'), 'dir') == 7 && ~strcmp(pwd, igw_root)
    OutputDir = fullfile(pwd, 'Output_NZ_4Region_Intergen');
else
    OutputDir = fullfile(igw_root, 'output', char(Profile_ID));
end

if ~exist(OutputDir, 'dir')
    mkdir(OutputDir);
end
end
