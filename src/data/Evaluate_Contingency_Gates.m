function GateEval = Evaluate_Contingency_Gates(ContingencySpec, Years_vec, StateMetrics)
%% VECTORIZED LAYER 3 CONTINGENCY GATE EVALUATOR
% File: src/data/Evaluate_Contingency_Gates.m
% Evaluates all declarative gates in ContingencySpec across time vector Years_vec [N_t x 1]
% against realized or projected time-series fields in StateMetrics.
%
% Behavior:
%   - If Logic == 'calendar_only' or StateMetrics is empty/missing a metric, falls back cleanly
%     to Fallback_Year (and logs missing metrics only when StateMetrics was non-empty).
%   - Uses 100% CPU logical mask operations over [N_t x 1] column vectors (zero time loops).
%   - Returns GateEval.<Target_Track> with Unlock_Year, Is_Unlocked_Vec [N_t x 1],
%     and Rel_Tau_Vec = max(0, Years_vec - Unlock_Year) ready for vectorized interp1 into RolloutSpec!

if nargin < 3
    StateMetrics = struct();
end

y_col = double(Years_vec(:));
N_t   = numel(y_col);

GateEval            = struct();
GateEval.Policy_ID  = ContingencySpec.Policy_ID;
GateEval.Years_vec  = y_col;
GateEval.Tracks     = struct();

% Seed default SS2_Transition fallback in case policy has zero gates
def_ss2 = ContingencySpec.Default_SS2_Fallback_Yr;
GateEval.SS2_Unlock_Year = def_ss2;

N_gates = numel(ContingencySpec.Gates);
for g = 1:N_gates
    gate      = ContingencySpec.Gates{g};
    track_key = regexprep(gate.Target_Track, '[^a-zA-Z0-9_]', '_');
    min_yr    = get_num_def(gate, 'Min_Year', 0);
    fb_yr     = get_num_def(gate, 'Fallback_Year', def_ss2);
    logic_str = lower(get_str_def(gate, 'Logic', 'all_of'));

    elig_mask = (y_col >= min_yr);

    if strcmp(logic_str, 'calendar_only') || isempty(fieldnames(StateMetrics)) || ~isfield(gate, 'Conditions') || isempty(gate.Conditions)
        unlock_yr = max(min_yr, fb_yr);
        used_fallback = true;
    else
        conds = gate.Conditions;
        n_c   = numel(conds);
        if strcmp(logic_str, 'any_of')
            comb_mask = false(N_t, 1);
        else
            comb_mask = true(N_t, 1);
        end

        all_metrics_present = true;
        for c = 1:n_c
            cond_c = conds{c};
            m_name = cond_c.Metric;
            if ~isfield(StateMetrics, m_name) || isempty(StateMetrics.(m_name))
                all_metrics_present = false;
                break;
            end
            m_vec = double(StateMetrics.(m_name)(:));
            if numel(m_vec) == 1
                m_vec = repmat(m_vec, N_t, 1);
            end
            c_mask = eval_vec_op(m_vec, cond_c.Op, double(cond_c.Threshold));
            if strcmp(logic_str, 'any_of')
                comb_mask = comb_mask | c_mask;
            else
                comb_mask = comb_mask & c_mask;
            end
        end

        if ~all_metrics_present
            unlock_yr     = max(min_yr, fb_yr);
            used_fallback = true;
        else
            sustain_k = max(1, round(get_num_def(gate, 'Sustain_Steps', 1)));
            if sustain_k > 1 && N_t >= sustain_k
                % Vectorized moving-sum persistence check: requires sustain_k consecutive satisfied steps!
                run_sum   = conv(double(comb_mask), ones(sustain_k, 1), 'full');
                sust_mask = (run_sum(1:N_t) >= sustain_k);
            else
                sust_mask = comb_mask;
            end
            pass_idx = find(elig_mask & sust_mask, 1, 'first');
            if isempty(pass_idx)
                unlock_yr     = Inf; % Conditions never met over horizon -> gate stays locked!
                used_fallback = false;
            else
                unlock_yr     = y_col(pass_idx);
                used_fallback = false;
            end
        end
    end

    is_open_vec = (y_col >= unlock_yr);
    tau_vec     = max(0.0, y_col - unlock_yr) .* double(is_open_vec);

    GateEval.Tracks.(track_key) = struct( ...
        'Gate_ID',        gate.Gate_ID, ...
        'Unlock_Year',    unlock_yr, ...
        'Used_Fallback',  used_fallback, ...
        'Is_Open_Vec',    is_open_vec, ...
        'Rel_Tau_Vec',    tau_vec);

    if strcmpi(track_key, 'SS2_Transition')
        GateEval.SS2_Unlock_Year = unlock_yr;
    end
end

end

%% --- LOCAL HELPERS ---
function m = eval_vec_op(vec, op_str, thresh)
switch strtrim(op_str)
    case '>='
        m = (vec >= thresh);
    case '>'
        m = (vec >  thresh);
    case '<='
        m = (vec <= thresh);
    case '<'
        m = (vec <  thresh);
    case {'==', '='}
        m = (abs(vec - thresh) < 1e-9);
    case {'~=', '!='}
        m = (abs(vec - thresh) >= 1e-9);
    otherwise
        error('IGWelfare:InvalidGateOp', 'Unsupported comparison operator "%s" in contingency gate.', op_str);
end
end

function v = get_num_def(S, f, d)
if isstruct(S) && isfield(S, f) && isnumeric(S.(f)) && ~isempty(S.(f)), v = S.(f); else, v = d; end
end

function v = get_str_def(S, f, d)
if isstruct(S) && isfield(S, f) && (ischar(S.(f)) || isstring(S.(f))), v = char(S.(f)); else, v = d; end
end
