function out = compute_spectopo_psd(EEG, ~)
% Estimate power at each frequency with Welch's method (EEGLAB spectopo).
% spectopo returns power in dB. FOOOF needs linear power, so this converts it.

EEG = eeg_checkset(EEG);
fs = EEG.srate;  % samples per second
win = round(2 * fs); % each welch window is 2 seconds
noverlap = round(win * 0.5); % neighbouring windows overlap by half
nfft = 2^nextpow2(win); % FFT length, rounded up to a power of 2

[specdB, f] = spectopo(EEG.data(:, :), EEG.pnts, fs, ...
    'winsize', win, 'overlap', noverlap, 'nfft', nfft, ...
    'plot', 'off', 'verbose', 'off'); 

f = f(:); % frequencies as one column
psd = 10.^(specdB / 10); % convert dB to linear power 
keep = f >= 1 & f <= 100; % keep 1-100 hz (FOOOF uses 3-40; noise floor uses 40-100)
out.freqs_psd = f(keep);
out.psd_all = max(psd(:, keep), eps); % eps avoid zeros, which break a log spectrum    
end
