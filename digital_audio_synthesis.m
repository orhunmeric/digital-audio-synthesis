%% Exercise 2 - Digital Audio Synthesis
% Generates a chord progression via subtractive + additive synthesis,
% applies an ADSR envelope, and adds cathedral reverb.

fs = 44100;   % sampling frequency [Hz]
T  = 2.5;     % duration of each note/chord [s]

%% --- Step 3: ADSR Envelope --------------------------------------------------
Ns   = round(T * fs);
t    = (0:Ns-1) / fs;
t_kp = [0,  0.16*T, 0.32*T, 0.6*T, T];
a_kp = [0,  1,      0.7,    0.7,   0];
adsr = interp1(t_kp, a_kp, t, 'pchip');

%% --- Step 4: Chord Progression -----------------------------------------------
% Reference: A4 = 440 Hz
% Semitones from A4: D5=+5, A4=0, B4=+2, F#4=-3, G4=-2
% Progression: D, A, Bm, F#m, G, D, G, A
A4    = 440;
roots = A4 * 2.^([5, 0, 2, -3, -2, 5, -2, 0] / 12);
types = {'major','major','minor','minor','major','major','major','major'};

progression = zeros(1, Ns * numel(roots));
for k = 1:numel(roots)
    chord = generateChord(roots(k), types{k}, fs, T);
    chord = chord .* adsr;
    progression((k-1)*Ns + (1:Ns)) = chord;
end

player = audioplayer(progression, fs);
play(player);
audiowrite('chord_progression.wav', progression(:), fs);
fprintf('Wrote chord_progression.wav\n');

%% --- Step 5: Digital Reverb --------------------------------------------------
ir_file = 'impulse_revcathedral.wav';
if ~isfile(ir_file)
    warning('"%s" not found. Place it in your current folder:\n  %s\nSkipping reverb.', ir_file, pwd);
else
    [ir, fs_cat] = audioread(ir_file);
    ir  = mean(ir, 2)';
    r   = fs / fs_cat;
    ir_up = interp(ir, r, 4, 1/r);

    M     = 2^nextpow2(length(progression) + length(ir_up) - 1);
    Y_rev = fft(progression, M) .* fft(ir_up, M);
    y_rev = real(ifft(Y_rev));
    y_rev = y_rev / max(abs(y_rev));

    player2 = audioplayer(y_rev, fs);
    play(player2);
    audiowrite('chord_progression_reverb.wav', y_rev(:), fs);
    fprintf('Wrote chord_progression_reverb.wav\n');
end


%% ============= LOCAL FUNCTIONS ===============================================

function note = generateNote(f0, fs, T)
    Ns = round(T * fs);
    t  = (0:Ns-1) / fs;

    saw     = sawtooth(2*pi*f0*t);
    lfo_sig = sin(2*pi*(f0/200)*t);
    pwm     = double(saw < lfo_sig);

    wp      = f0;
    ws      = 16 * f0;
    BT      = ws - wp;
    fc      = (wp + ws)/2;
    fc_norm = fc / fs;

    N = ceil(4 * fs / BT);
    if mod(N, 2) ~= 0, N = N + 1; end

    n       = -N/2 : N/2;
    h_ideal = 2 * fc_norm * sinc(2 * fc_norm * n);
    w_bart  = bartlett(N+1)';
    h       = h_ideal .* w_bart;
    h       = h / sum(h);

    note = conv(pwm, h, 'same');
end


function chord = generateChord(f0, type, fs, T)
    if strcmp(type, 'major')
        ratios = [1,  2^(4/12),  2^(7/12)];
    else
        ratios = [1,  2^(3/12),  2^(7/12)];
    end

    Ns    = round(T * fs);
    chord = zeros(1, Ns);
    for k = 1:3
        chord = chord + generateNote(f0 * ratios(k), fs, T);
    end
    chord = chord / max(abs(chord));
end