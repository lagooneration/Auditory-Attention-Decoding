function g = gammatonefir_corrected(freqs, fs, N, betamul, mode)
% GAMMATONEFIR_CORRECTED - Corrected wrapper for gammatonefir
% Uses working pattern 3 from validation

g = gammatonefir(freqs, fs);
end

function freqs = erbspacebw_corrected(f_min, f_max, spacing)
% ERBSPACEBW_CORRECTED - Corrected wrapper for erbspacebw
freqs = erbspacebw(f_min, f_max, spacing);
freqs = freqs(:)'; % Ensure row vector
end
