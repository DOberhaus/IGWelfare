% prove_cond  Count Table14 rows breaking Flow = p*c_cond (Document 2B s5.1), tol 0.015 kNZD.
% Behaviour-based: locates the tests/ folder via read_csv_cells on the path, then reads
% ../Output_NZ_4Region_Intergen/Table14_*.csv next to it. Run once with main's tree
% and once with the branch's tree on the path. Prints exactly one line.
here = fileparts(which('read_csv_cells'));
if isempty(here), error('prove_cond:path', 'tests/ (read_csv_cells.m) must be on the path'); end
outDir = fullfile(fileparts(here), 'Output_NZ_4Region_Intergen');
regions = {'National', 'Auckland', 'Large', 'Small', 'Urban', 'Rural'};
scens = {'SS0', 'SS1', 'SS2'};
nBad = 0;
for r = 1:numel(regions)
    fname = fullfile(outDir, ['Table14_FiscalLedger_6Gate_Decomp_' regions{r} '.csv']);
    [hdr, cells] = read_csv_cells(fname);
    for s = 1:numel(scens)
        pop  = str2double(cells(:, find(strcmp(hdr, [scens{s} '_Pop_Pct']))));
        flow = str2double(cells(:, find(strcmp(hdr, [scens{s} '_CohortFlow_kNZD']))));
        cond = str2double(cells(:, find(strcmp(hdr, [scens{s} '_CondPerChild_kNZD']))));
        nBad = nBad + sum(abs(flow - pop / 100 .* cond) > 0.015);
    end
end
if nBad > 0, v = 'RED'; else, v = 'GREEN'; end
disp(['cond ' v ' ' num2str(nBad)]);
