function out = compute_spectopo_psd(EEG, ~)
% Welch PSD via EEGLAB spectopo (2-s Hamming, 50% overlap).
% spectopo returns dB; convert to linear power for FOOOF.

EEG = eeg_checkset(EEG);
fs = EEG.srate;
win = round(2 * fs);
noverlap = round(win * 0.5);
nfft = 2^nextpow2(win);

[specdB, f] = spectopo(EEG.data(:, :), EEG.pnts, fs, ...
    'winsize', win, 'overlap', noverlap, 'nfft', nfft, ...
    'plot', 'off', 'verbose', 'off');

f = f(:);
psd = 10.^(specdB / 10);
keep = f >= 1 & f <= 100;
out.freqs_psd = f(keep);
out.psd_all = max(psd(:, keep), eps);
end
