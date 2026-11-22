function val = getfield_def(S, fname, default_val)
if isfield(S, fname)
    val = S.(fname);
else
    val = default_val;
end
end
