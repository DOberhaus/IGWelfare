function varargout = IGW_Restore_Tables(varargin)
%% SINGLE-SOURCE TABLE RESTORATION AFTER .MAT CHECKPOINT LOAD
% File: src/utils/IGW_Restore_Tables.m
% Restores serialized struct-backed tables in GNU Octave via vfi_restore_tables
% while passing native MATLAB tables through untouched with zero caller branching.

has_shim = (exist('vfi_restore_tables', 'file') ~= 0);
varargout = cell(1, nargin);
for k = 1:nargin
    if has_shim
        varargout{k} = vfi_restore_tables(varargin{k});
    else
        varargout{k} = varargin{k};
    end
end
end
