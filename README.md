# Digital Audio Synthesis

A MATLAB implementation of digital audio synthesis combining **subtractive synthesis**, **additive synthesis**, an **ADSR envelope**, and **convolution reverb** to generate a chord progression.

## What It Does

The script synthesises a full chord progression (D → A → Bm → F#m → G → D → G → A) and optionally applies a cathedral impulse response for realistic reverb.

### Pipeline

```
PWM Oscillator (sawtooth + LFO)
        ↓
  Low-pass FIR filter  (subtractive synthesis)
        ↓
  Additive chord stacking  (root + major/minor third + fifth)
        ↓
  ADSR envelope
        ↓
  Convolution reverb  (optional — requires impulse response file)
        ↓
  WAV output
```

## Signal Chain Details

### Oscillator
Each note uses a **pulse-width modulated (PWM)** waveform derived from a sawtooth wave modulated by a low-frequency oscillator (LFO) at `f0 / 200 Hz`.

### Filter
A **Bartlett-windowed FIR low-pass filter** cuts harmonics above the first alias. Passband edge is set at `f0`, stopband at `16 × f0`, giving a transition band that scales with pitch.

### ADSR Envelope
Piecewise cubic Hermite interpolation (`pchip`) over five keypoints:

| Stage   | Time (× T) | Amplitude |
|---------|-----------|-----------|
| Start   | 0.00      | 0.0       |
| Attack  | 0.16      | 1.0       |
| Decay   | 0.32      | 0.7       |
| Sustain | 0.60      | 0.7       |
| Release | 1.00      | 0.0       |

### Chord Progression
Reference pitch: **A4 = 440 Hz**

| Chord | Root (semitones from A4) | Type  |
|-------|--------------------------|-------|
| D     | +5                       | Major |
| A     |  0                       | Major |
| Bm    | +2                       | Minor |
| F#m   | −3                       | Minor |
| G     | −2                       | Major |
| D     | +5                       | Major |
| G     | −2                       | Major |
| A     |  0                       | Major |

Each chord is built from three voices: **root**, **third** (±4 or ±3 semitones), and **perfect fifth** (+7 semitones).

### Reverb
Convolution reverb via FFT overlap with an external cathedral impulse response. The IR is resampled to match `fs = 44100 Hz` before convolution. The output is peak-normalised.

## Output Files

| File | Description |
|------|-------------|
| `chord_progression.wav` | Dry chord progression |
| `chord_progression_reverb.wav` | Chord progression with cathedral reverb |

## Requirements

- MATLAB R2019b or later
- Signal Processing Toolbox (`sawtooth`, `bartlett`, `interp`)
- *(Optional)* `impulse_revcathedral.wav` — cathedral impulse response placed in the working directory for reverb output

## Usage

```matlab
% Run from the MATLAB command window or editor
run('digital_audio_synthesis.m')
```

Output WAV files are written to the current working directory. Audio plays back automatically via `audioplayer`.

## Parameters

| Variable | Default | Description |
|----------|---------|-------------|
| `fs` | 44100 Hz | Sampling frequency |
| `T` | 2.5 s | Duration per chord |
| `A4` | 440 Hz | Reference pitch |
