function hash_hex = IGW_MD5_Hex(payload)
%% SINGLE-SOURCE CROSS-PLATFORM MD5 DIGEST HELPER (STRUCT OR CHAR/STRING)
% File: src/utils/IGW_MD5_Hex.m
% Computes a lower-case 32-character hexadecimal MD5 digest for any char/string
% or JSON-serializable struct/array across GNU Octave (hash) and MATLAB (Java MessageDigest).

if ischar(payload)
    str = payload;
elseif isstring(payload)
    str = char(payload);
else
    str = jsonencode(payload);
end

hash_hex = '';
try
    if exist('OCTAVE_VERSION', 'builtin') ~= 0
        hash_hex = lower(hash('md5', str));
    elseif usejava('jvm')
        md = java.security.MessageDigest.getInstance('MD5');
        if ~isempty(str)
            raw_bytes = uint8(unicode2native(str, 'UTF-8'));
            if ~isempty(raw_bytes)
                md.update(typecast(raw_bytes(:), 'int8'));
            end
        end
        hash_hex = lower(reshape(dec2hex(typecast(md.digest(), 'uint8'), 2)', 1, []));
    elseif exist('mMD5', 'file') ~= 0
        md5_fun = @() mMD5(str);
        [~, hash_hex] = evalc('md5_fun()');
        hash_hex = lower(strtrim(hash_hex));
    end
catch
    hash_hex = '';
end

end
