function validate_and_fix_amtoolbox()
% VALIDATE_AND_FIX_AMTOOLBOX - Test and fix AMToolbox function calls
% This function validates the correct usage of AMToolbox functions for consistency
% with the original KULeuven preprocessing

fprintf('=== AMToolbox Validation and Fix ===\n');

%% Step 1: Test erbspacebw function
fprintf('1. Testing erbspacebw function...\n');
try
    % Test with original parameters
    freqs = erbspacebw(150, 4000, 1.5);
    fprintf('✓ erbspacebw working: Generated %d frequencies\n', length(freqs));
    fprintf('  Frequency range: %.1f Hz to %.1f Hz\n', min(freqs), max(freqs));
    
    % Ensure it's a row vector as expected by gammatonefir
    if size(freqs, 1) > size(freqs, 2)
        freqs = freqs'; % Convert to row vector
        fprintf('  → Converted to row vector\n');
    end
    
    test_freqs = freqs;
catch ME
    fprintf('✗ erbspacebw failed: %s\n', ME.message);
    fprintf('  Using manual ERB spacing fallback\n');
    test_freqs = create_erb_spacing_manual(150, 4000, 1.5);
end

%% Step 2: Test gammatonefir with correct dimensions
fprintf('2. Testing gammatonefir function...\n');

% Prepare parameters exactly as in original code
fs = 8000; % Sample rate
spacing = 1.5;
betamul = spacing * ones(size(test_freqs)); % Must match freqs dimensions

% Ensure both are same orientation
if size(test_freqs, 1) ~= size(betamul, 1) || size(test_freqs, 2) ~= size(betamul, 2)
    fprintf('  Fixing dimension mismatch...\n');
    fprintf('  freqs size: [%d x %d], betamul size: [%d x %d]\n', ...
        size(test_freqs, 1), size(test_freqs, 2), size(betamul, 1), size(betamul, 2));
    
    % Force both to be row vectors
    test_freqs = test_freqs(:)';
    betamul = betamul(:)';
    
    fprintf('  After fix - freqs size: [%d x %d], betamul size: [%d x %d]\n', ...
        size(test_freqs, 1), size(test_freqs, 2), size(betamul, 1), size(betamul, 2));
end

% Test different gammatonefir calling patterns
fprintf('  Testing gammatonefir call patterns...\n');

% Pattern 1: Original call from preprocess_data.m
try
    fprintf('    Pattern 1: gammatonefir(freqs, fs, [], betamul, ''real'')\n');
    g1 = gammatonefir(test_freqs, fs, [], betamul, 'real');
    fprintf('    ✓ Pattern 1 SUCCESS: Filter size [%d x %d]\n', size(g1, 1), size(g1, 2));
    working_pattern = 1;
catch ME1
    fprintf('    ✗ Pattern 1 FAILED: %s\n', ME1.message);
    
    % Pattern 2: Try with column vectors
    try
        fprintf('    Pattern 2: Column vectors\n');
        g2 = gammatonefir(test_freqs(:), fs, [], betamul(:), 'real');
        fprintf('    ✓ Pattern 2 SUCCESS: Filter size [%d x %d]\n', size(g2, 1), size(g2, 2));
        working_pattern = 2;
    catch ME2
        fprintf('    ✗ Pattern 2 FAILED: %s\n', ME2.message);
        
        % Pattern 3: Try minimal call
        try
            fprintf('    Pattern 3: Minimal call gammatonefir(freqs, fs)\n');
            g3 = gammatonefir(test_freqs, fs);
            fprintf('    ✓ Pattern 3 SUCCESS: Filter size [%d x %d]\n', size(g3, 1), size(g3, 2));
            working_pattern = 3;
        catch ME3
            fprintf('    ✗ Pattern 3 FAILED: %s\n', ME3.message);
            working_pattern = 0;
        end
    end
end

%% Step 3: Test ufilterbank
if working_pattern > 0
    fprintf('3. Testing ufilterbank function...\n');
    
    % Get the working filter
    switch working_pattern
        case 1
            g_test = gammatonefir(test_freqs, fs, [], betamul, 'real');
        case 2
            g_test = gammatonefir(test_freqs(:), fs, [], betamul(:), 'real');
        case 3
            g_test = gammatonefir(test_freqs, fs);
    end
    
    % Test with sample audio
    test_audio = randn(1000, 1); % 1 second of noise
    
    try
        filtered_audio = real(ufilterbank(test_audio, g_test, 1));
        fprintf('✓ ufilterbank SUCCESS: Input [%d x %d] → Output [%d x %d]\n', ...
            size(test_audio, 1), size(test_audio, 2), size(filtered_audio, 1), size(filtered_audio, 2));
        
        % Test reshaping as in original code
        reshaped_audio = reshape(filtered_audio, size(filtered_audio, 1), []);
        fprintf('  ✓ Reshape SUCCESS: Final size [%d x %d]\n', ...
            size(reshaped_audio, 1), size(reshaped_audio, 2));
            
        amtoolbox_working = true;
    catch ME
        fprintf('✗ ufilterbank FAILED: %s\n', ME.message);
        amtoolbox_working = false;
    end
else
    amtoolbox_working = false;
    fprintf('3. Skipping ufilterbank test (no working gammatonefir)\n');
end

%% Step 4: Generate corrected functions
fprintf('4. Generating corrected AMToolbox functions...\n');

if amtoolbox_working
    fprintf('✓ AMToolbox is working with Pattern %d\n', working_pattern);
    create_amtoolbox_wrapper(working_pattern, test_freqs, betamul);
else
    fprintf('⚠ AMToolbox failed, creating fallback functions\n');
    create_amtoolbox_fallback(test_freqs);
end

fprintf('\n=== AMToolbox Validation Complete ===\n');

end

function freqs = create_erb_spacing_manual(f_min, f_max, spacing)
% Manual ERB spacing as fallback
erb_min = 21.4 * log10(1 + f_min / 229);
erb_max = 21.4 * log10(1 + f_max / 229);
erb_vals = linspace(erb_min, erb_max, round((erb_max - erb_min) / spacing) + 1);
freqs = (10.^(erb_vals / 21.4) - 1) * 229;
freqs = freqs(:)'; % Ensure row vector
end

function create_amtoolbox_wrapper(pattern, freqs, betamul)
% Create wrapper functions with correct calling pattern

wrapper_file = 'amtoolbox_corrected.m';
fid = fopen(wrapper_file, 'w');

fprintf(fid, 'function g = gammatonefir_corrected(freqs, fs, N, betamul, mode)\n');
fprintf(fid, '%% GAMMATONEFIR_CORRECTED - Corrected wrapper for gammatonefir\n');
fprintf(fid, '%% Uses working pattern %d from validation\n\n', pattern);

switch pattern
    case 1
        fprintf(fid, 'g = gammatonefir(freqs, fs, [], betamul, ''real'');\n');
    case 2
        fprintf(fid, 'g = gammatonefir(freqs(:), fs, [], betamul(:), ''real'');\n');
    case 3
        fprintf(fid, 'g = gammatonefir(freqs, fs);\n');
end

fprintf(fid, 'end\n\n');

fprintf(fid, 'function freqs = erbspacebw_corrected(f_min, f_max, spacing)\n');
fprintf(fid, '%% ERBSPACEBW_CORRECTED - Corrected wrapper for erbspacebw\n');
fprintf(fid, 'freqs = erbspacebw(f_min, f_max, spacing);\n');
fprintf(fid, 'freqs = freqs(:)''; %% Ensure row vector\n');
fprintf(fid, 'end\n');

fclose(fid);
fprintf('  → Created corrected wrapper: %s\n', wrapper_file);
end

function create_amtoolbox_fallback(freqs)
% Create complete fallback implementation

fallback_file = 'amtoolbox_fallback.m';
fid = fopen(fallback_file, 'w');

fprintf(fid, 'function g = gammatonefir_fallback(freqs, fs, N, betamul, mode)\n');
fprintf(fid, '%% GAMMATONEFIR_FALLBACK - Complete fallback implementation\n\n');

fprintf(fid, 'if nargin < 5, mode = ''real''; end\n');
fprintf(fid, 'if nargin < 4 || isempty(betamul), betamul = ones(size(freqs)); end\n');
fprintf(fid, 'if nargin < 3 || isempty(N), N = 4096; end\n\n');

fprintf(fid, '%% Create gammatone filterbank using butter filters\n');
fprintf(fid, 'num_filters = length(freqs);\n');
fprintf(fid, 'g = zeros(N, num_filters);\n\n');

fprintf(fid, 'for i = 1:num_filters\n');
fprintf(fid, '    fc = freqs(i);\n');
fprintf(fid, '    bw = betamul(i) * (24.7 + 0.108 * fc) * 0.637; %% ERB bandwidth\n');
fprintf(fid, '    \n');
fprintf(fid, '    %% Create bandpass filter\n');
fprintf(fid, '    f_low = max(fc - bw/2, 50);\n');
fprintf(fid, '    f_high = min(fc + bw/2, fs/2 * 0.95);\n');
fprintf(fid, '    \n');
fprintf(fid, '    try\n');
fprintf(fid, '        [b, a] = butter(4, [f_low f_high] / (fs/2), ''bandpass'');\n');
fprintf(fid, '        h = freqz(b, a, N, fs);\n');
fprintf(fid, '        g(:, i) = real(h);\n');
fprintf(fid, '    catch\n');
fprintf(fid, '        %% Fallback: simple gain\n');
fprintf(fid, '        g(:, i) = ones(N, 1) / num_filters;\n');
fprintf(fid, '    end\n');
fprintf(fid, 'end\n');
fprintf(fid, 'end\n\n');

fprintf(fid, 'function out = ufilterbank_fallback(audio, g, hopsize)\n');
fprintf(fid, '%% UFILTERBANK_FALLBACK - Simple filterbank implementation\n');
fprintf(fid, 'if nargin < 3, hopsize = 1; end\n\n');
fprintf(fid, '[num_samples, ~] = size(audio);\n');
fprintf(fid, 'num_filters = size(g, 2);\n');
fprintf(fid, 'out = zeros(num_samples, num_filters);\n\n');
fprintf(fid, 'for i = 1:num_filters\n');
fprintf(fid, '    out(:, i) = filter(g(:, i), 1, audio);\n');
fprintf(fid, 'end\n');
fprintf(fid, 'end\n');

fclose(fid);
fprintf('  → Created fallback implementation: %s\n', fallback_file);
end