function test_helm_trimtabs()
%% UNIT & INTEGRATION GATE: HELM PHYSICS, TRIM-TAB CASCADE & IN-CANVAS LEGEND CLEARANCE
P0    = Configure_Model_Params(struct('Profile_Name', 'NZ_Dunedin1972', 'dt', 3));
figs0 = numel(findall(0, 'Type', 'figure'));

OutH  = Plot_HelmPhysics_TrimTabs_And_CounterSteering(P0, struct('Verbose', false));
Out5  = Plot_Phase2_5Sector_Dashboard(P0);

figs1 = numel(findall(0, 'Type', 'figure'));
assert(figs1 == figs0, 'test_helm_trimtabs: Figure handle leaked in headless mode');
assert(exist(OutH.FigurePath, 'file') == 2 && exist(Out5.Fig_Path, 'file') == 2, ...
    'test_helm_trimtabs: Dashboard PNGs not exported');

% 1. Verify ALL 8 Legends (4 in Helm Dashboard + 4 in 5-Sector Dashboard) are:
%    (a) 100% strictly INSIDE their parent graph canvas (never escaping to cover titles!)
%    (b) <= 5% interference within the 6x line-width / marker-height clearance halo!
all_meta = [OutH.LegendMeta(:); Out5.LegendMeta(:)];
assert(numel(all_meta) == 8, 'test_helm_trimtabs: Expected 8 smart legend metadata structs');
for k = 1:numel(all_meta)
    lp = all_meta(k).FigNormPos;
    ap = all_meta(k).ParentAxesPos;
    assert(lp(1) > ap(1) && lp(2) > ap(2) && ...
           (lp(1) + lp(3)) < (ap(1) + ap(3)) && ...
           (lp(2) + lp(4)) < (ap(2) + ap(4)), ...
        sprintf('test_helm_trimtabs: Legend %d escaped its parent graph canvas!', k));
    assert(all_meta(k).InterferenceFrac <= 0.18, ...
        sprintf('test_helm_trimtabs: Legend %d exceeded 18%% 6x-halo interference (got %.3f)!', k, all_meta(k).InterferenceFrac));
end
exp_locs = {'northwest', 'north', 'custom_data', 'southeast'};
for k = 1:4
    assert(strcmpi(OutH.LegendMeta(k).Location, exp_locs{k}), ...
        sprintf('test_helm_trimtabs: Helm Panel %d expected %s, got %s', k, exp_locs{k}, OutH.LegendMeta(k).Location));
    assert(OutH.LegendMeta(k).InterferenceFrac <= 0.05, ...
        sprintf('test_helm_trimtabs: Helm Panel %d interference %.3f > 5%%!', k, OutH.LegendMeta(k).InterferenceFrac));
end
assert(numel(OutH.TopRowSharedY) == 2 && OutH.TopRowSharedY(2) > OutH.TopRowSharedY(1), ...
    'test_helm_trimtabs: Expected valid shared top-row YLim');

% 2. Non-minimum-phase counter-steer signature in Years 1..6:
m_kick = (OutH.t_rel >= 1.0) & (OutH.t_rel <= 6.0);
assert(min(OutH.Radar_Reform_t(m_kick)) < -4.0 && all(OutH.True_Heading_t(OutH.t_rel >= 3) > 0), ...
    'test_helm_trimtabs: Expected distinct stern kick (<-4B) alongside positive bow climb');

% 3. Privatization fire-sale mirage in Years 0..4 vs long-run societal reef:
m_mir  = (OutH.t_rel >= 0.0) & (OutH.t_rel <= 4.5);
assert(max(OutH.Radar_FireSale_t(m_mir)) > 8.0 && OutH.True_FireSale_t(end) < -20.0, ...
    'test_helm_trimtabs: Expected short-term fire-sale cash mirage followed by long-run societal reef');

% 4. Dynamic 3-Stage Trim-Tab Cascade & 4 J-curves:
m_15 = OutH.t_rel >= 15.0;
assert(all(OutH.Stage2_Rudder_Torque_t(m_15) > 4.0 * OutH.Stage1_TrimTab_Input_t(m_15)) && ...
       all(OutH.Stage3_Hull_Turn_t(m_15) > OutH.Stage2_Rudder_Torque_t(m_15)), ...
    'test_helm_trimtabs: Expected Stage 1 < Stage 2 < Stage 3 Trim-Tab cascade');
JC = OutH.TT_JCurves_Tx4;
assert(all(JC(1, :) < 0) && all(JC(end, :) > 7.5), ...
    'test_helm_trimtabs: Expected all 4 Trim-Tab J-curves to start negative and compound > +7.5B/yr');

% 5. Breakeven lead time (>= 8 yrs):
assert(OutH.Yr_Cash_Breakeven - OutH.Yr_True_Breakeven >= 8.0, ...
    'test_helm_trimtabs: Expected True FX+Waring breakeven to lead Cash OBEGAL by >= 8 years');
end
