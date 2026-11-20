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
narrativeMap('NODE_6')  = 'Node 6 — Public ECE & Farm-to-ECE / Marae Kai Wraparound (Lane C Pub Dev): Universal First 2000 Days public ECE and Whanau Ora / Te Korowai Mokopuna wraparound (G_ece_1: 0.045 -> 0.110 -> 0.130) paired with local Ka Ora, Ka Ako / CEFS Farm-to-ECE nutrition (+24-33% veg intake, d=1.20; +26.6 pp parent nutrition crowding-in; 46% take-home garden produce; ~13.00 kNZD/yr cohort flow in SS1) [Ref 11, 14, 37, 47, 56].';
narrativeMap('NODE_7')  = 'Node 7 — High-Intensity Public ECE & Subsidy Co-Funding (Lane C Pub Dev): Public ECE co-funding and s_sub = 10% fee subsidy for households investing at the upper rungs of the convex d_grid_ic power grid [Ref 11, 14].';
narrativeMap('NODE_8')  = 'Node 8 — Private Parental & Whanau ECE Commitment (Parental Warm Gold, 60% Lane A Priv Cash + 40% Lane B Waring/Parental Time): Out-of-pocket early enrichment (1 - s_sub)*ic, child housing/nutrition share, and imputed parental + extended whanau care time K_whanau(k) (~15.80 kNZD/yr cohort flow; ~18.5-19.9 kNZD/yr conditional per non-corner child, matching Stats NZ HES child-cost benchmarks) [Ref 21, 26, 47].';

% --- GATE 3 (J = 5, Adolescent Gate, Ages 12-14 — Nodes 9..13) ---
narrativeMap('NODE_9')  = 'Node 9 — Household Unemployment & Truancy Remediation (Deep Red, Lane D Pub Remed): Vote Social Development hardship top-ups, Alternative Education (>25 kNZD/student), and Attendance / Youth Justice early intervention driven by family job-loss shocks (z1-z2). Compresses sharply from ~8.90 kNZD/yr in SS0 to ~1.10 kNZD/yr in SS1 as GE job creation and Tuakana mentoring insulate teens [Ref 16, 18, 55].';
narrativeMap('NODE_10') = 'Node 10 — Psychosocial Trauma, CAMHS & ACC ISSC (Crimson-Plum, Lane D Pub Remed — The 38% Clinical Floor): Vote Health CAMHS acute youth mental health care and ACC Integrated Services for Sensitive Claims (ISSC, +193% claims surge) arising from severe bullying (32-35%), Youth19 clinical depression (23%), and sexual/relational trauma. Compresses from ~4.70 kNZD/yr in SS0 to ~1.40 kNZD/yr in SS1, visibly representing the 38% clinical persistence floor that requires specialized clinical trauma care beyond school mentoring [Ref 17, 19, 20, 38].';
narrativeMap('NODE_11') = 'Node 11 — Public Secondary Schooling (d_2, Lane C Pub Dev): Standard state intermediate and secondary schooling outlays (~14.0 kNZD/student/yr conditional rate) [Ref 12, 15].';
narrativeMap('NODE_12') = 'Node 12 — Montessori Erdkinder, Tuakana-Teina & Youth Food-Hub Mentoring (Teal, Lane C Pub Dev): Public funding for Graeme Dingle Stars/Project K, Kura Kaupapa Maori / Pasifika Tuakana academies, CEFS Food Youth Initiative (FYI) & GrowingChange land-based youth enterprises (92% non-recidivism), KiVa peer training, and Planet Youth cohorts (expanding from 17.3% / ~1.10 kNZD/yr in SS0 to 57.3% / ~6.50 kNZD/yr in SS1) [Ref 18, 20, 55, 56].';
narrativeMap('NODE_13') = 'Node 13 — Private Adolescent Commitment (Parental Warm Gold, 62% Lane A Priv Cash + 38% Lane B Parental/Whanau Time): Household expenditure on adolescent nutrition, digital/educational tools, extracurriculars, and structured parent-adolescent connection time (~15.4-18.8 kNZD/yr cohort flow; ~19.0-19.8 kNZD/yr conditional per non-crisis teen) [Ref 21, 47, 55].';

% --- GATE 4 (J = 6..7, Adult Skill Launch, Age 20 — Nodes 14..16) ---
narrativeMap('NODE_14') = 'Node 14 — Struggling Tier Launch (h1-h2, Age 20, 82% Lane D Remed + 18% Lane C): Calibrated to the Dunedin Study 22.0% high-burden cohort in SS0 (~10.00 kNZD/yr -> ~2.20 kNZD/yr in SS1 as struggling share drops to 4.0% in SS1 and 1.5% in SS2). Primary conduit for ACC Loss of Potential Earnings (LOPE at 80% adult minimum wage) and NEET entry [Ref 16, 38].';
narrativeMap('NODE_15') = 'Node 15 — Core Skill Tier Launch (h3-h5, Age 20): Vocational, apprenticeship, and polytechnic/tertiary launch coupled with the universal Age-20 Youth Capital Grant E (0.065 in SS1, 0.080 in SS2) [Ref 6, 12].';
narrativeMap('NODE_16') = 'Node 16 — Thriving Tier Launch (h6-h7, Age 20): High-capability university and entrepreneurial launch (expanding from 23.5% / ~13.00 kNZD/yr in SS0 to 57.3% / ~26.20 kNZD/yr in SS1), seeded with Youth Capital Grant E to clear the 20% Kiyotaki LVR deposit cliff and build z_h enterprises in NZ [Ref 2, 4, 7].';

% --- GATE 5 (J = 8..11, Prime Career & Enterprise Sorting, Ages 30-54 — Nodes 17..21) ---
narrativeMap('NODE_17') = 'Node 17 — Chronic Adversity & Benefit/NEET Trap (Deep Crimson): Retained adults (primarily from Struggling h1-h2 launch) trapped in chronic unemployment, Supported Living / Jobseeker dependency, ACC LOPE, or state care/justice sequelae (~20.1% of cohort in SS0 -> ~4.2% in SS1) [Ref 16, 37, 38].';
narrativeMap('NODE_18') = 'Node 18 — Domestic Core Workforce & Skilled Trades (Steel Blue): Retained adults in core domestic employment, skilled trades, healthcare, and education forming the stable working-age tax and service backbone [Ref 12, 31].';
narrativeMap('NODE_19') = 'Node 19 — Passive Land, Duopoly & Monopsony Rent Speculation [z_l Skew] (Ochre-Rust): In SS0, untaxed 1.6T NZD property appreciation and retail/wholesale oligopoly markups pull 61% of retained Thriving h6-h7 graduates and 12% of Core workers (~16.7% of cohort) into zero-sum rent extraction (z_l) while depressing Rural (-0.060) and Small (-0.010) job quality. Crushed to ~3.5% in SS1/SS2 by the tau_a = 1.5% wealth levy, tau_b = 25%->18% estate levy, and competition/procurement reform [Ref 2, 7, 36, 49].';
narrativeMap('NODE_20') = 'Node 20 — Productive Regional & National Enterprise Builders [z_h Innovators] (Emerald Teal): High-capability domestic founders, growers, engineers, and innovators deploying capital in positive-sum z_h enterprises. Surges from ~8.1% of the cohort in SS0 to ~46.5% in SS1 and ~56.0% in SS2 as Youth Capital Grant E, land-tax reform, and 1.60x-2.16x local food-hub procurement multipliers upgrade Rural/Small z_l -> z_h jobs and retire 85% of the SS1 geographic transfer top-up [Ref 2, 4, 7, 49, 56].';
narrativeMap('NODE_21') = 'Node 21 — Emigrated Abroad [Trans-Tasman Brain Drain] (Purple): Young adults who departed to Australia/OECD between ages 20 and 35 via the 4x5 Gumbel sorting matrix Pi_mig (~11.1% in SS0 -> ~7.5% in SS1) [Ref 23, 24, 25].';

% --- GATE 6 (J = 10..16, Annualized Adult Fiscal Ledger — Nodes 22..29) ---
narrativeMap('NODE_22') = 'Node 22 — Exit 1: State Care Legacy Outlay (Deep Crimson, Lane D Remed): Annualized adult Oranga Tamariki care legacy and Royal Commission abuse-in-care statutory liability (14.1% of Exits 1,2,4 remediation; ~1.1 kNZD/yr in SS0, collapsing below 0.35 kNZD/yr and visually suppressed in SS1/SS2) [Ref 16, 37].';
narrativeMap('NODE_23') = 'Node 23 — Exit 2: Avoidable Hospitalisation & CAMHS Outlay (Burnt Rust, Lane D Remed): Annualized preventable adult hospital admissions, acute psychiatric care, and ACC ISSC trauma rehabilitation (25.8% of Exits 1,2,4 remediation; ~2.1 kNZD/yr in SS0 -> ~0.6 kNZD/yr in SS1) [Ref 16, 38].';
narrativeMap('NODE_24') = 'Node 24 — Exit 4: Benefit, ACC LOPE & Justice Burden (Dark Ruby, Lane D Remed): Annualized Supported Living, Jobseeker hardship, ACC Loss of Potential Earnings (LOPE at 80% min wage), and Corrections outlays (60.1% of Exits 1,2,4 remediation; ~4.9 kNZD/yr in SS0 -> ~1.1 kNZD/yr in SS1) [Ref 16, 38].';
narrativeMap('NODE_25') = 'Node 25 — Base Infrastructure, Public Health & NZ Superannuation (Ochre-Brown, Lane C Outlay): Model attributes ~10.2 kNZD/yr per retained domestic adult (0.068*NZD_Scale = 6.46 kNZD/yr for roads, core infrastructure, and baseline public health + 0.22*p_super*NZD_Scale = 3.76 kNZD/yr annualized universal NZ Superannuation across J=10..16), totaling ~9.1 kNZD/yr cohort-weighted [Ref 13, 31, 36].';
narrativeMap('NODE_26') = 'Node 26 — GST, Productive Capital & Estate Tax Pool (Public Steel Blue, GOOD Revenue 1): Annualized consumption tax (tau_c = 15%), capital/wealth levy (tau_k = 20%, tau_a = 1.5%), and estate bequest levy (tau_b = 25%->18%). Allocates 50% of net reform surplus to the Public Infrastructure Reinvestment Pool (Omega_reinv at 1.65x multiplier) [Ref 2, 6, 36].';
narrativeMap('NODE_27') = 'Node 27 — Working-Age PAYE Income Tax (Teal, GOOD Revenue 2): Annualized working-age labor income tax receipts (tau_l * w * z * h * (l - Ih)). Allocates 50% of net reform surplus to the 2050 Sovereign Debt-Sinking Fund (Omega_debt), retiring 17.5B-21.85B NZD of debt per cohort wave and—combined with the 85% retirement of the SS1 geographic transfer—unlocking the -3.75 pp PAYE rate cut (22.0% -> 18.25% at Super Age 64) in SS2 [Ref 1, 2, 31, 35, 49, 56].';
narrativeMap('NODE_28') = 'Node 28 — Exit 3: Lower-Skill Foregone Tax Drag (Muted Mauve, BEYOND Drag 1): Uncollected PAYE and GST revenue (~8.4 kNZD/yr per chronically struggling adult) lost because childhood/adolescent hardship trapped potential builders in low-wage/NEET trajectories [Ref 11, 14].';
narrativeMap('NODE_29') = 'Node 29 — Abroad Brain-Drain Lost Tax (Purple, BEYOND Drag 2): Annualized domestic PAYE, GST, and estate tax revenue permanently lost to Australia/OECD from emigrated graduates [Ref 23, 24, 25].';

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
    narrativeMap('6->12') = 'SS1/SS2 Dual-Gate Complementarity (Wedge 1): First 2000 Days ECE & Farm-to-ECE nutrition gains (Node 6) are banked and compounded by universalized Montessori Erdkinder / Tuakana-Teina / CEFS FYI adolescent mentoring (Node 12, 57.3%-65.0% coverage), eliminating delta_fade = 0.22 skill depreciation [Ref 11, 15, 18, 56].';
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


% --- GATE 4 (14..16) -> GATE 5 (17..21, Career & Enterprise Sorting) ---
narrativeMap('14->17') = 'Dunedin 78% Persistence Trap: Retained Struggling h1-h2 youth (Node 14) disproportionately enter Chronic Adversity, NEET, and long-term benefit/LOPE trajectories (Node 17) [Ref 16, 38].';
narrativeMap('14->18') = 'Late-Launch Workforce Stabilisation: 22% (SS0) -> 32% (SS1) of retained h1-h2 youth stabilise into the Domestic Core Workforce (Node 18) via adult Ben-Porath training (Ih) [Ref 12].';
narrativeMap('15->17') = 'Cyclical or health-driven downward drift from Core Skill Launch (Node 15) into Chronic Adversity (Node 17; cut from 9% in SS0 to 4% in SS1).';
narrativeMap('15->18') = 'Core Workforce Backbone: 73%-76% of retained Core Skill (h3-h5) launches establish careers in domestic trades, nursing, teaching, and services (Node 18) [Ref 31].';
narrativeMap('15->19') = 'In SS0, 12% of Core-tier households divert savings into leveraged rental property speculation (z_l, Node 19); cut to 2%-4% in SS1/SS2 [Ref 2, 7].';
narrativeMap('15->20') = 'Upward Regional & SME Entrepreneurial Mobility: Core-tier tradespeople, growers, and technicians launching productive z_h enterprises (Node 20; rising from 6% in SS0 to 16%-20% in SS1/SS2 via 1.60x-2.16x regional procurement multipliers and bankable local contracts) [Ref 2, 4, 49, 56].';
narrativeMap('15->21') = 'Trans-Tasman emigration of Core Skill (h3-h5) trades and healthcare workers to Australia (Node 21; cut from 11% in SS0 to 6% in SS1) [Ref 23, 24].';
narrativeMap('16->18') = 'Retained Thriving (h6-h7) graduates entering senior public service, clinical, and core professional roles (Node 18).';
narrativeMap('16->19') = 'Murphy-Shleifer-Vishny Rent-Seeking Drain (Node 16 -> Node 19): In SS0, 61% of retained Thriving h6-h7 talent is captured by passive land/property speculation and tax arbitrage (z_l). Compresses to 14% in SS1 and 6% in SS2 [Ref 2, 7].';
narrativeMap('16->20') = 'Guvenen, MSV & Regional z_l->z_h Builder Pivot (Node 16 -> Node 20): Retained Thriving h6-h7 graduates deploying talent in high-productivity z_h enterprises (surging from 29% of retained top talent in SS0 to 78% in SS1 and 88% in SS2, lifting Rural CE to +20.63% and retiring 85% of the geographic transfer top-up) [Ref 2, 7, 49, 56].';
narrativeMap('16->21') = 'High-Skill Brain Drain (Node 16 -> Node 21): 22% conditional emigration of top graduates in SS0 cut to 12% in SS1 via Youth Capital Grant E, metro rent cooling, and z_h firm wage premiums [Ref 23, 24, 25].';

% --- GATE 5 (17..21, Career Strata) -> GATE 6 (22..29, Exact Adult Fiscal Ledger) ---
narrativeMap('17->22') = 'Chronic Adversity stratum (Node 17) driving Exit 1 State Care Legacy and Royal Commission abuse-in-care liabilities (Node 22; 14.1% of Exits 1,2,4 remediation) [Ref 16, 37].';
narrativeMap('17->23') = 'Chronic Adversity stratum (Node 17) driving Exit 2 Avoidable Hospitalisation, acute CAMHS, and ACC ISSC trauma care (Node 23; 25.8% of Exits 1,2,4 remediation) [Ref 16, 38].';
narrativeMap('17->24') = 'Chronic Adversity stratum (Node 17) driving Exit 4 Supported Living, Jobseeker hardship, ACC LOPE (80% min wage), and Corrections outlays (Node 24; 60.1% of Exits 1,2,4 remediation) [Ref 16, 38].';
narrativeMap('17->25') = 'Per-capita attribution of baseline public infrastructure, roads, public health, and NZ Superannuation (~10.2 kNZD/yr per retained adult) to the Chronic Adversity stratum (Node 25) [Ref 13, 31].';
narrativeMap('17->26') = 'Modest GST consumption tax paid out of benefit and low-wage income by the Chronic Adversity stratum (Node 26).';
narrativeMap('17->27') = 'Minimal working-age PAYE tax paid during intermittent employment spells by the Chronic Adversity stratum (Node 27).';
narrativeMap('17->28') = 'Exit 3 Lower-Skill Foregone Tax (Node 28): ~8.4 kNZD/yr per chronically struggling adult in uncollected PAYE and GST revenue due to early/adolescent skill deprivation [Ref 11, 14].';
narrativeMap('18->23') = 'Residual avoidable hospitalisation and health shocks among the Domestic Core Workforce (Node 18 -> Node 23).';
narrativeMap('18->24') = 'Cyclical unemployment or benefit spells among the Domestic Core Workforce (Node 18 -> Node 24).';
narrativeMap('18->25') = 'Per-capita attribution of roads, core infrastructure, public health (6.46 kNZD/yr), and universal NZ Superannuation (3.76 kNZD/yr) to the Domestic Core Workforce (~10.2 kNZD/yr conditional; NZ Treasury LTFS & He Tirohanga Mokopuna) [Ref 13, 31, 36].';
narrativeMap('18->26') = 'Domestic Core Workforce (Node 18) generating steady GST, capital, and estate tax revenues (Node 26) [Ref 31].';
narrativeMap('18->27') = 'Domestic Core Workforce (Node 18) generating the broad middle-income PAYE income tax base (Node 27) [Ref 31].';
narrativeMap('19->25') = 'Per-capita attribution of public infrastructure, health, and NZ Superannuation (~10.2 kNZD/yr per adult) utilized by the Passive Land/Rent Speculation stratum (Node 19 -> Node 25) [Ref 31, 36].';
narrativeMap('19->26') = 'Passive Land/Rent Speculators (z_l, Node 19) paying GST and land/estate levies on property holdings (Node 26) [Ref 2, 36].';
narrativeMap('19->27') = 'Reduced PAYE income tax yield from Passive Land/Rent Speculators (z_l, Node 19 -> Node 27) due to untaxed capital gains and income sheltering in SS0 [Ref 2, 7].';
narrativeMap('20->25') = 'Per-capita attribution of public infrastructure, health, and NZ Superannuation (~10.2 kNZD/yr per adult) utilized by Productive Enterprise Builders (z_h, Node 20 -> Node 25) [Ref 31, 36].';
narrativeMap('20->26') = 'Guvenen/MSV Builder Capital & GST Dividend (Node 20 -> Node 26): Productive Enterprise Builders (z_h) generate surging GST, corporate/capital, and estate tax receipts, funding the 50% Public Infrastructure Reinvestment Pool (Omega_reinv) [Ref 2, 7, 36].';
narrativeMap('20->27') = 'High-Wage Builder PAYE Surplus Engine (Node 20 -> Node 27): Productive Enterprise Builders (z_h) generate high-wage PAYE surpluses and replace 85% of the SS1 geographic transfer, funding the 50% Sovereign Debt-Sinking Fund (Omega_debt) and unlocking the -3.75 pp (18.25%) PAYE tax cut in SS2 [Ref 1, 2, 31, 35, 49, 56].';
narrativeMap('21->29') = '100% Exact Mapping of Emigrated Abroad Stratum (Node 21 -> Node 29): Every dollar of foregone domestic PAYE, GST, and estate tax from emigrated young adults flows directly into Abroad Brain-Drain Lost Tax [Ref 23, 24, 25].';

end
