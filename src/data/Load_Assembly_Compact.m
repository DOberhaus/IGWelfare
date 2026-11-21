function CompactSpec = Load_Assembly_Compact(DataSpecOrID)
%% PURE LOADER FOR DOCUMENT 1F FIVE CITIZENS' ASSEMBLY CONTINGENT CONTRACTS
% File: src/data/Load_Assembly_Compact.m
% Loads profiles/<Profile_ID>/policies/citizens_assembly_contracts.csv with
% automatic profile inheritance (NZ_GUiNZ2009 -> NZ_Dunedin1972), schema checks,
% and deterministic MD5 digesting.

if nargin < 1 || isempty(DataSpecOrID)
    DataSpec = Load_Empirical_Profile('NZ_Dunedin1972');
elseif isstruct(DataSpecOrID)
    DataSpec = DataSpecOrID;
else
    DataSpec = Load_Empirical_Profile(char(DataSpecOrID));
end

igw_root = getappdata(0, 'IGW_ROOT_DIR');
if isempty(igw_root)
    igw_root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
end

cand_dirs = {fullfile(igw_root, 'profiles', DataSpec.Profile_ID, 'policies')};
if isfield(DataSpec, 'Parent_Profile_ID') && ~isempty(DataSpec.Parent_Profile_ID)
    cand_dirs{end+1} = fullfile(igw_root, 'profiles', DataSpec.Parent_Profile_ID, 'policies');
end
cand_dirs{end+1} = fullfile(igw_root, 'profiles', 'NZ_Dunedin1972', 'policies');

pol_dir = '';
for k = 1:numel(cand_dirs)
    if exist(fullfile(cand_dirs{k}, 'citizens_assembly_contracts.csv'), 'file') == 2
        pol_dir = cand_dirs{k};
        break;
    end
end
if isempty(pol_dir)
    error('IGWelfare:MissingAssemblyContracts', 'Could not locate citizens_assembly_contracts.csv for profile %s.', DataSpec.Profile_ID);
end

CT = Read_IGW_CSV(fullfile(pol_dir, 'citizens_assembly_contracts.csv'));
nK = numel(CT.Contract_ID);
if nK < 15
    error('IGWelfare:IncompleteAssemblyCompact', 'Expected >= 15 ranged contracts across Assemblies A1..A5, found %d.', nK);
end

Assemblies = {'A1_EarlyPotential'; 'A2_Housing_Whanau'; 'A3_Civic_Mycelium'; 'A4_Enterprise_Tax'; 'A5_Sovereign_Infra'};

CompactSpec = struct();
CompactSpec.Profile_ID     = DataSpec.Profile_ID;
CompactSpec.Source_Dir     = pol_dir;
CompactSpec.Assemblies     = Assemblies;
CompactSpec.Contract_Table = CT;
CompactSpec.N_Contracts    = nK;
CompactSpec.Digest         = IGW_MD5_Hex(CT);
end
