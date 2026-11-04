function narrativeMap = getFiscalRibbonNarratives(phase_code)
%% GETFISCALRIBBONNARRATIVES
% Returns containers.Map keyed by 'NODE_num' (1..28) and 'srcNum->dstNum' for the
% 6-Gate (28-Node) Lifecycle Fiscal Sankey (Option 2: Gate 1 4-Node Split + Gate 3 5-Node Split).
% Enforces strict suffix-unit formatting (kNZD/yr) and explicit 4-Lane Waring / Landlord attribution.
narrativeMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
is_ref = ~strcmpi(phase_code, 'SS0');

% =========================================================================
% 1. NODE-LEVEL DESCRIPTIONS (NODES 1..28 ACROSS GATES 1..6)
% =========================================================================
% --- GATE 1 (J = 1, Birth, Age 0 — Nodes 1..4) ---
narrativeMap('NODE_1')  = 'Node 1 — Acute Hardship Tier 3 Support (Deep Crimson, Lane D Pub Remed): Emergency Special Needs Grants, transitional/emergency housing at birth, and intensive neonatal/Oranga Tamariki crisis support for the ~9.8% (SS0) -> ~2.6% (SS1) born into DEP-17 9+ severe material hardship (~1.85 kNZD/yr cohort flow in SS0 -> ~0.45 kNZD/yr in SS1; ~18.9 kNZD/yr per severe-hardship birth) [Ref 37, 48].';
narrativeMap('NODE_2')  = 'Node 2 — Residual AHC Paper Support & Unpaid Whanau Buffer (Burnt Rust, Lane D Landlord Capture + Lane B Waring Time): Captures the ~14.2% (SS0) -> ~5.1% (SS1) in the AHC-50 squeeze who qualify on paper for Accommodation Supplement and abated Working for Families (~1.85 kNZD/yr in SS0 -> ~0.70 kNZD/yr in SS1). In high-rent metros (Q_reg = 2.05-3.10), AS payments are captured by landlords (Lane D), while in provincial regions unpaid extended whanau care K_whanau(k) (Lane B, Marilyn Waring 1988) bridges the First 2000 Days gap [Ref 47, 48].';
narrativeMap('NODE_3')  = 'Node 3 — Universal Birth Benefit (Public Steel Blue, Lane C Pub Dev): Paid Parental Leave (PPL), Best Start universal first-year tax credit, Lead Maternity Carer (LMC), and Well Child / Tamariki Ora scaffolding across 100% of births (~2.70 kNZD/yr in SS0 -> ~5.20 kNZD/yr in SS1) [Ref 14, 37].';
narrativeMap('NODE_4')  = 'Node 4 — Private Birth Out-of-Pocket Commitment (Parental Warm Gold, 63% Lane A Priv Cash + 37% Lane B Priv Time): Private household infant setup, nursery/housing space (0.045*Q_reg), and Foregone parental wage time across the ~76.0% (SS0) -> ~92.3% (SS1) Secure Buffer cohort (~9.60 kNZD/yr in SS0 -> ~12.40 kNZD/yr in SS1; ~16.7 kNZD/yr conditional per buffered birth) [Ref 1, 21].';

% --- GATE 2 (J = 2..3, First 2000 Days ECE Gate, Ages 0-5 — Nodes 5..8) ---
narrativeMap('NODE_5')  = 'Node 5 — ECE Corner + Benefit Need (Lane D Pub Remed): Reactive benefit top-ups, emergency housing, and early health/care remediation for the ~24.0% (SS0) -> ~5.7% (SS1) trapped at the ic = 0 private investment corner (~12.30 kNZD/yr in SS0 -> ~2.70 kNZD/yr in SS1; ~47.6 kNZD/yr conditional per corner child) [Ref 1, 37, 48].';
narrativeMap('NODE_6')  = 'Node 6 — Public ECE Wraparound (Lane C Pub Dev): Universal First 2000 Days public ECE and Whanau Ora / Te Korowai Mokopuna wraparound (G_ece_1: 0.045 -> 0.110 -> 0.130, amplified by 1.15x downward Tuakana role-modeling and regional K_whanau co-care; ~13.00 kNZD/yr cohort flow in SS1, or ~13.5 kNZD/yr per child) [Ref 11, 14, 37, 47].';
narrativeMap('NODE_7')  = 'Node 7 — High-Intensity Public ECE & Subsidy Co-Funding (Lane C Pub Dev): Public ECE co-funding and s_sub = 10% fee subsidy for households investing at the upper rungs of the convex d_grid_ic power grid [Ref 11, 14].';
narrativeMap('NODE_8')  = 'Node 8 — Private Parental & Whanau ECE Commitment (Parental Warm Gold, 60% Lane A Priv Cash + 40% Lane B Waring/Parental Time): Out-of-pocket early enrichment (1 - s_sub)*ic, child housing/nutrition share, and imputed parental + extended whanau care time K_whanau(k) (~15.80 kNZD/yr cohort flow; ~18.5-19.9 kNZD/yr conditional per non-corner child, matching Stats NZ HES child-cost benchmarks) [Ref 21, 26, 47].';

% --- GATE 3 (J = 5, Adolescent Gate, Ages 12-14 — Nodes 9..13) ---
narrativeMap('NODE_9')  = 'Node 9 — Household Unemployment & Truancy Remediation (Deep Red, Lane D Pub Remed): Vote Social Development hardship top-ups, Alternative Education (>25 kNZD/student), and Attendance / Youth Justice early intervention driven by family job-loss shocks (z1-z2). Compresses sharply from ~8.90 kNZD/yr in SS0 to ~1.10 kNZD/yr in SS1 as GE job creation and Tuakana mentoring insulate teens [Ref 16, 18, 55].';
narrativeMap('NODE_10') = 'Node 10 — Psychosocial Trauma, CAMHS & ACC ISSC (Crimson-Plum, Lane D Pub Remed — The 38% Clinical Floor): Vote Health CAMHS acute youth mental health care and ACC Integrated Services for Sensitive Claims (ISSC, +193% claims surge) arising from severe bullying (32-35%), Youth19 clinical depression (23%), and sexual/relational trauma. Compresses from ~4.70 kNZD/yr in SS0 to ~1.40 kNZD/yr in SS1, visibly representing the 38% clinical persistence floor that requires specialized clinical trauma care beyond school mentoring [Ref 17, 19, 20, 38].';
narrativeMap('NODE_11') = 'Node 11 — Public Secondary Schooling (d_2, Lane C Pub Dev): Standard state intermediate and secondary schooling outlays (~14.0 kNZD/student/yr conditional rate) [Ref 12, 15].';
narrativeMap('NODE_12') = 'Node 12 — Montessori Erdkinder & Tuakana-Teina Public Mentoring (Teal, Lane C Pub Dev): Public funding for Graeme Dingle Stars/Project K, Kura Kaupapa Maori / Pasifika Tuakana academies, vertical-whanau state schools, KiVa peer-ecology training, and Planet Youth community cohorts (expanding from 17.3% / ~1.10 kNZD/yr in SS0 to 57.3% / ~6.50 kNZD/yr in SS1) [Ref 18, 20, 55].';
narrativeMap('NODE_13') = 'Node 13 — Private Adolescent Commitment (Parental Warm Gold, 62% Lane A Priv Cash + 38% Lane B Parental/Whanau Time): Household expenditure on adolescent nutrition, digital/educational tools, extracurriculars, and structured parent-adolescent connection time (~15.4-18.8 kNZD/yr cohort flow; ~19.0-19.8 kNZD/yr conditional per non-crisis teen) [Ref 21, 47, 55].';

% --- GATE 4 (J = 6..7, Adult Skill Launch, Age 20 — Nodes 14..16) ---
narrativeMap('NODE_14') = 'Node 14 — Struggling Tier Launch (h1-h2, Age 20, 82% Lane D Remed + 18% Lane C): Calibrated to the Dunedin Study 22.0% high-burden cohort in SS0 (~10.00 kNZD/yr -> ~2.20 kNZD/yr in SS1 as struggling share drops to 4.0% in SS1 and 1.5% in SS2). Primary conduit for ACC Loss of Potential Earnings (LOPE at 80% adult minimum wage) and NEET entry [Ref 16, 38].';
narrativeMap('NODE_15') = 'Node 15 — Core Skill Tier Launch (h3-h5, Age 20): Vocational, apprenticeship, and polytechnic/tertiary launch coupled with the universal Age-20 Youth Capital Grant E (0.065 in SS1, 0.080 in SS2) [Ref 6, 12].';
narrativeMap('NODE_16') = 'Node 16 — Thriving Tier Launch (h6-h7, Age 20): High-capability university and entrepreneurial launch (expanding from 23.5% / ~13.00 kNZD/yr in SS0 to 57.3% / ~26.20 kNZD/yr in SS1), seeded with Youth Capital Grant E to clear the 20% Kiyotaki LVR deposit cliff and build z_h enterprises in NZ [Ref 2, 4, 7].';

% --- GATE 5 (J = 10, Age 30 Annual Fiscal Balance — Nodes 17..22) ---
narrativeMap('NODE_17') = 'Node 17 — Age 30 Exits 1, 2, 4 Remediation (BAD Outlay 1, Lane D): Oranga Tamariki care legacy, avoidable hospitalisation/CAMHS, ACC LOPE, Supported Living / Jobseeker hardship, and Corrections outlays (~10.00 kNZD/yr in SS0 -> ~2.70 kNZD/yr in SS1; ~32.0 kNZD/yr per struggling h1-h2 adult) [Ref 16, 37, 38].';
narrativeMap('NODE_18') = 'Node 18 — Age 30 Core Infrastructure, Roads & Base Health (BAD Outlay 2, Lane C): Baseline public goods, transport infrastructure, and primary health per retained young adult (~3.90 kNZD/yr) [Ref 31, 36].';
narrativeMap('NODE_19') = 'Node 19 — Age 30 GST & Productive Capital Tax (GOOD Revenue 1, Lane C): Consumption tax (tau_c = 15%) plus book-value land/wealth levy (tau_a = 1.5%) and z_h enterprise equity revenues (~4.20 kNZD/yr in SS0 -> ~8.20 kNZD/yr in SS1; funds the 50% Public Infrastructure Reinvestment Pool Omega_reinv) [Ref 1, 2, 36].';
narrativeMap('NODE_20') = 'Node 20 — Age 30 PAYE Income Tax (GOOD Revenue 2, Lane C): Working-age labor income tax receipts (~4.40 kNZD/yr in SS0 -> ~8.90 kNZD/yr in SS1; funds the 50% Sovereign Debt-Sinking Fund Omega_debt) [Ref 1, 31].';
narrativeMap('NODE_21') = 'Node 21 — Age 30 Exit 3 Lower-Skill Foregone Tax (BEYOND Drag 1, Lane D): Uncollected PAYE and GST tax revenue due to childhood/adolescent skill deprivation trapping adults in h1-h2 rather than h3-h7 (~1.80 kNZD/yr in SS0 -> ~0.90 kNZD/yr in SS1) [Ref 11, 14].';
narrativeMap('NODE_22') = 'Node 22 — Age 30 Emigrated Abroad Foregone Tax (BEYOND Drag 2, Lane D): Domestic PAYE and GST revenue lost to Australia/OECD via trans-Tasman youth brain drain (~1.10-1.30 kNZD/yr) [Ref 23, 24, 25].';

% --- GATE 6 (J = 11..16, Career to Retirement Fiscal Destiny — Nodes 23..28) ---
narrativeMap('NODE_23') = 'Node 23 — Career-to-Retirement Exits 1, 2, 4 Ongoing Burden (BAD Outlay 1, Lane D): Chronic adult hospital, disability/SLP, ACC LOPE, and justice costs across ages 35-99 (~7.10 kNZD/yr in SS0 -> ~2.00 kNZD/yr in SS1) [Ref 16, 38].';
narrativeMap('NODE_24') = 'Node 24 — NZ Superannuation, Geriatric Health & Core Infrastructure (BAD Outlay 2, Lane C): Universal NZ Superannuation (p_super = 0.18 at Age 65 in SS0/SS1 and Age 64 in SS2) plus late-life health and infrastructure (~5.40-6.50 kNZD/yr) [Ref 13, 26, 31].';
narrativeMap('NODE_25') = 'Node 25 — Career GST, Productive Capital & Estate Tax Pool (GOOD Revenue 1, Lane C): Prime-career GST, tau_a = 1.5% wealth levy, and tau_b = 25%->18% estate levy on the 1.6T NZD property transfer wave (~8.40 kNZD/yr in SS0 -> ~16.90 kNZD/yr in SS1; 50% allocated to Public Infrastructure Reinvestment at 1.65x multiplier) [Ref 2, 6, 36].';
narrativeMap('NODE_26') = 'Node 26 — Career Builder PAYE Income Tax (GOOD Revenue 2, Lane C): Prime-earning PAYE tax receipts (~1.70 kNZD/yr in SS0 -> ~5.30 kNZD/yr in SS1, even after cutting the statutory PAYE rate from 22.0% to 18.85% in SS2; 50% allocated to Sovereign Debt Sinking) [Ref 1, 2, 31].';
narrativeMap('NODE_27') = 'Node 27 — Career Exit 3 Foregone Tax Drag (BEYOND Drag 1, Lane D): Cumulative career tax-base loss from unbuffered early/adolescent skill deficits (~1.60 kNZD/yr in SS0 -> ~1.10 kNZD/yr in SS1).';
narrativeMap('NODE_28') = 'Node 28 — Permanent Abroad Tax Loss (BEYOND Drag 2, Lane D): Career and retirement tax base permanently lost to Australia/OECD from unretained graduates [Ref 23, 24, 25].';

% =========================================================================
% 2. RIBBON-LEVEL TRANSITIONS (GATES 1 -> 2 -> 3 -> 4 -> 5 -> 6)
% =========================================================================
% --- GATE 1 (1..4) -> GATE 2 (5..8) ---
if ~is_ref
    narrativeMap('1->5') = 'SS0 Tier 3 Hardship Trap: Acute DEP-17 9+ birth deprivation flows directly into the Gate 2 ECE Corner + Benefit Need remediation ledger (Node 5, ~47.6 kNZD/yr conditional public cost) [Ref 1, 37, 48].';
    narrativeMap('2->5') = 'SS0 Paper-Support Failure & Landlord Capture: In high-rent Auckland/Large metros (Q_reg = 2.05-3.10), Accommodation Supplement payments are captured by landlords while nuclear isolation from extended whanau pushes Residual AHC Squeeze families into the Node 5 corner [Ref 47, 48].';
    narrativeMap('2->6') = 'SS0 Marilyn Waring Unpaid Whanau Care Rescue (Lane B): In Rural and Small provincial regions (K_whanau = 0.38-0.42), unpaid alloparental care by nearby kaumatua and aunties bridges the statutory transfer gap, rescuing squeezed Node 2 infants into Moderate ECE (Node 6) [Ref 26, 47].';
else
    narrativeMap('1->6') = 'SS1/SS2 Proactive Tier 3 Wraparound: Universal First 2000 Days investment (G_ece_1 = 0.110-0.130) and Whanau Ora / Barnardos navigators lift 78%-92% of severe-hardship births out of reactive crisis into Node 6 Public ECE Wraparound [Ref 14, 37].';
    narrativeMap('2->6') = 'SS1/SS2 Rent Cooling + Kuia Time + Universal ECE: Cooling metro rents (Q_mult), Super Age 64 Kuia time (+8.1% Phi_time), and universal ECE shift Node 2 families from landlord-captured subsidies into productive Node 6 early enrichment [Ref 26, 47].';
end
narrativeMap('3->5') = 'Universal PPL/BestStart baseline support flowing to families still trapped in the Gate 2 cash corner.';
narrativeMap('3->6') = 'Universal Birth Benefit (PPL + BestStart) seamlessly (bridging) into Universal First 2000 Days Public ECE Wraparound (Node 6) [Ref 14, 37].';
narrativeMap('3->7') = 'Universal Birth Benefit co-funding families entering High-Intensity Public ECE (Node 7).';
narrativeMap('4->8') = 'Parental Warm Gold Continuity (Lane A Cash + Lane B Time): Secure-buffer birth commitment flowing into ongoing First 2000 Days private parental and whanau investment (~18.5-18.7 kNZD/yr conditional per child) [Ref 21, 47].';

% --- GATE 2 (5..8) -> GATE 3 (9..13) ---
if ~is_ref
    narrativeMap('5->9')  = 'SS0 Household Unemployment & Truancy Escalation: Children from the ic=0 corner hit by family job loss (z1-z2) drive ~8.90 kNZD/yr in Vote Social Development, Alternative Education, and Youth Justice remediation (Node 9) [Ref 16, 18].';
    narrativeMap('5->10') = 'SS0 Compounded Psychosocial & Trauma Crisis: Early corner deprivation compounds with bullying (32-35%), Youth19 clinical depression (23%), and sexual/relational harm to drive ~4.70 kNZD/yr in acute CAMHS and ACC ISSC sensitive claims (Node 10) [Ref 19, 20, 38].';
    narrativeMap('6->9')  = 'SS0 Unbuffered Mid-Childhood Job Shock: Without universal Gate 3 mentoring, family unemployment shocks at ages 12-14 pull moderate-ECE children into Node 9 truancy/hardship remediation [Ref 15, 18].';
    narrativeMap('6->10') = 'SS0 Cross-Income Adolescent Psychosocial Shock (lambda_psy): Cyberbullying, algorithmic compulsion, and age-12 depressive escalation (52.4% in GUiNZ) pull even middle-income students into Node 10 CAMHS / ACC ISSC trauma care [Ref 17, 19, 20, 38].';
else
    narrativeMap('5->9')  = 'SS1/SS2 Compressed HH Unemployment Remediation (~8.90 -> ~1.10 kNZD/yr): GE job creation (z_h) and 14-fold higher Tuakana mentoring access under stress (2% -> 28%) slash truancy and benefit remediation [Ref 2, 18, 55].';
    narrativeMap('5->10') = 'SS1/SS2 The 38% Clinical Persistence Floor (~4.70 -> ~1.40 kNZD/yr): While KiVa peer norms, Planet Youth family buffers, and Tuakana mentoring prevent primary detachment, Node 10 retains the 38% clinical floor for acute psychiatric and ACC ISSC trauma requiring specialized clinical care [Ref 20, 38, 55].';
    narrativeMap('5->12') = 'SS1/SS2 14-Fold Surge in Mentoring Rescue (2% -> 28%): Vulnerable children from Gate 2 are actively routed into Graeme Dingle Stars/Project K, Kura, and Montessori Erdkinder mentoring (Node 12) [Ref 18, 55].';
    narrativeMap('6->12') = 'SS1/SS2 Dual-Gate Complementarity (Wedge 1 = +3.26% CE): First 2000 Days ECE gains (Node 6) are banked and compounded by universalized Montessori / Tuakana-Teina adolescent mentoring (Node 12, 57.3%-65.0% coverage), eliminating delta_fade = 0.22 skill depreciation [Ref 11, 15, 18].';
end
narrativeMap('6->11') = 'Public First 2000 Days ECE cohorts progressing into standard state secondary schooling (Node 11).';
narrativeMap('7->11') = 'High-intensity ECE cohorts entering standard state secondary schooling.';
narrativeMap('7->12') = 'High-intensity ECE cohorts continuing into Montessori Erdkinder & Tuakana-Teina leadership (Node 12).';
narrativeMap('8->11') = 'Private parental early-childhood commitment supporting students in standard public schooling.';
narrativeMap('8->12') = 'Private parental and whanau care co-investing alongside public Tuakana-Teina mentoring.';
narrativeMap('8->13') = 'Parental Warm Gold Continuity (Gate 2 -> Gate 3, Lane A Cash + Lane B Time): Early parental and whanau commitment continuing into ages 12-14 adolescent support and Planet Youth family connection time (~19.0-19.8 kNZD/yr conditional) [Ref 21, 47, 55].';

% --- GATE 3 (9..13) -> GATE 4 (14..16) ---
narrativeMap('9->14')  = 'Unbuffered household unemployment and truancy at ages 12-14 (-0.22 log-skill penalty under phi_2 = -0.95) driving youth into the Dunedin 22% Struggling Adult Launch Tier (h1-h2, Node 14) [Ref 11, 16].';
narrativeMap('10->14') = 'Untreated adolescent psychosocial morbidity and sexual/relational trauma (Node 10) driving NCEA non-completion, NEET entry, and statutory ACC Loss of Potential Earnings (LOPE at 80% minimum wage) in Node 14 [Ref 19, 38].';
narrativeMap('10->15') = 'Adolescents receiving timely CAMHS / ACC ISSC clinical rehabilitation who recover into the Core Adult Skill Tier (h3-h5, Node 15) [Ref 38].';
narrativeMap('11->14') = 'Skill fade-out (delta_fade = 0.22) in standard age-segregated schooling allowing vulnerable teens to slip into h1-h2 at Age 20 [Ref 15].';
narrativeMap('11->15') = 'Standard secondary schooling (Node 11) launching young adults into the Core Skill Tier (h3-h5, Node 15).';
narrativeMap('11->16') = 'High-achieving standard schooling students launching into the Thriving Skill Tier (h6-h7, Node 16).';
narrativeMap('12->15') = 'Tuakana-Teina and Graeme Dingle mentored youth launching solidly into the Core Skill Tier (h3-h5, Node 15) rather than struggling [Ref 18].';
narrativeMap('12->16') = 'Two-Way Ako / Protege Dividend (+0.11 to +0.14 log-skill boost): Montessori / Tuakana-Teina mentors launch into the Thriving Adult Skill Tier (h6-h7, Node 16) [Ref 18, 55].';
narrativeMap('13->15') = 'Private parental and whanau adolescent investment (Node 13) launching young adults into Core Skill careers (Node 15).';
narrativeMap('13->16') = 'Private parental cash + time commitment combining with Youth Capital Grant E to launch Thriving h6-h7 young adults (Node 16) [Ref 6, 12].';

% --- GATE 4 (14..16) -> GATE 5 (17..22, Age 30 Fiscal Balance) ---
narrativeMap('14->17') = 'Dunedin Study 74.1% Concentration Benchmark: Struggling h1-h2 young adults (Node 14) drive acute Age-30 Crown outlays across Exit 1 (State Care legacy), Exit 2 (Avoidable Hospitalisation/CAMHS), and Exit 4 (SLP/Jobseeker/ACC LOPE/Corrections) in Node 17 (~32.0 kNZD/yr per struggling adult) [Ref 16, 37, 38].';
narrativeMap('14->18') = 'Baseline core infrastructure and primary health usage by h1-h2 young adults (Node 18).';
narrativeMap('14->21') = 'Exit 3 Foregone Tax Drag at Age 30 (Node 21): Permanent PAYE and GST revenue lost because childhood/adolescent hardship trapped potential builders in h1-h2 [Ref 11, 14].';
narrativeMap('15->18') = 'Core Skill Tier (h3-h5) adults utilizing baseline public infrastructure and health services at Age 30 (Node 18).';
narrativeMap('15->19') = 'Core Skill Tier (h3-h5) adults generating GST and capital/land tax revenues at Age 30 (Node 19).';
narrativeMap('15->20') = 'Core Skill Tier (h3-h5) adults generating working-age PAYE income tax surpluses at Age 30 (Node 20).';
narrativeMap('15->22') = 'Trans-Tasman emigration of h3-h5 skilled trades and professionals to Australia (Node 22 Foregone Tax) [Ref 23, 24].';
narrativeMap('16->18') = 'Thriving Tier (h6-h7) adults utilizing baseline public infrastructure at Age 30.';
narrativeMap('16->19') = 'Guvenen et al. & MSV Builder Dividend at Age 30 (Node 19): Retained h6-h7 builders and entrepreneurs generate surging GST and z_h enterprise revenues, funding the 50% Public Infrastructure Reinvestment Pool (Omega_reinv) [Ref 2, 7, 36].';
narrativeMap('16->20') = 'High-Wage Builder PAYE Dividend at Age 30 (Node 20): Retained h6-h7 graduates power net fiscal surpluses, funding the 50% Sovereign Debt-Sinking Fund (Omega_debt) [Ref 2, 31].';
narrativeMap('16->22') = 'High-Skill Brain Drain Tax Loss at Age 30 (Node 22): Conditional emigration of h6-h7 graduates cut from 22% in SS0 to 12% in SS1 via Youth Grant E, Auckland rent cooling (-7.5% to -10.5%), and higher z_h firm wages [Ref 23, 24, 25].';

% --- GATE 5 (17..22) -> GATE 6 (23..28, Career to Retirement Fiscal Destiny) ---
narrativeMap('17->23') = 'Persistence of acute Exits 1, 2, 4 remediation burdens from Age 30 (Node 17) into chronic mid-career and geriatric hospital/benefit/LOPE outlays (Node 23; cut from ~7.10 kNZD/yr in SS0 to ~2.00 kNZD/yr in SS1) [Ref 16, 38].';
narrativeMap('18->24') = 'Progression from Age-30 base infrastructure/health (Node 18) into prime-career infrastructure, geriatric health, and universal NZ Superannuation (Node 24, optimized at Age 64 in SS2 for the +8.1% Kuia whanau dividend) [Ref 13, 26, 31].';
narrativeMap('19->25') = 'Compounding of Age-30 GST and z_h capital revenues into the Career GST, Productive Capital (tau_a = 1.5%), and Estate Tax (tau_b = 25%->18%) Pool (Node 25; ~8.40 -> ~16.90 kNZD/yr, mobilizing 11.5B-14.9B NZD/wave for public infrastructure at 1.65x multiplier) [Ref 2, 6, 36].';
narrativeMap('20->25') = 'Prime-age PAYE savings accumulating into productive enterprise equity, GST, and intergenerational estate tax receipts (Node 25) [Ref 2, 5, 6].';
narrativeMap('19->26') = 'Reinvestment of productive capital and infrastructure dividends boosting prime-career wage and PAYE tax receipts (Node 26).';
narrativeMap('20->26') = 'Prime-Career PAYE Surplus Engine (Node 26; ~1.70 -> ~5.30 kNZD/yr): Retires 17.5B-21.85B NZD of sovereign debt per cohort wave under the 2050 50/50 Protocol while unlocking a -3.15 pp working-age PAYE tax cut (22.0% -> 18.85% at Super Age 64) in SS2 [Ref 1, 31, 35].';
narrativeMap('21->27') = 'Compounding of Age-30 Exit 3 lower-skill tax drag into permanent career foregone tax revenue (Node 27).';
narrativeMap('22->28') = 'Age-30 emigrants who settle permanently in Australia/OECD, locking in lifetime career and estate tax loss (Node 28) [Ref 23, 25].';


end
