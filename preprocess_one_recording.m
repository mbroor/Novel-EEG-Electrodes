function outFile = preprocess_one_recording(dataDir, vhdrFile, chRange, outDir, pilotID, montage)
% Load BrainVision → filter → CleanLine → bad-ch reject → epoch → spectopo PSD.
% Saves *_alphaSNR.mat (out + EEG). Same pipeline for rest and walk.

EEG = pop_loadbv(dataDir, vhdrFile, [], chRange);
[~, baseName] = fileparts(vhdrFile);
EEG.setname = baseName;

EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 0);
EEG = pop_cleanline(EEG, 'bandwidth', 2, 'chanlist', 1:EEG.nbchan, ...
    'linefreqs', 60, 'plotfigures', 0, 'scanforlines', 0, 'winsize', 4, 'winstep', 1);
EEG = autoRejCh_func_CL(EEG, 3);
EEG = pop_clean_rawdata(EEG, 'flatline_crit', 5, 'channel_criterion', 0.8, ...
    'line_noise_criterion', 'off', 'highpass', 'off', ...
    'burst_criterion', 'off', 'window_criterion', 'off');

% Non-overlapping 4-s epochs (dummy events every 4 s after 1 s)
preSec = 1; epochSec = 4;
firstLat = preSec * EEG.srate + 1;
nEpochs = floor((EEG.pnts - preSec * EEG.srate) / (epochSec * EEG.srate));
if nEpochs < 1, error('Recording too short for epochs.'); end
EEG.event = [];
for e = 1:nEpochs
    EEG.event(e).type = 'dummy';
    EEG.event(e).latency = firstLat + (e - 1) * epochSec * EEG.srate;
    EEG.event(e).duration = 0;
end
EEG = eeg_checkset(EEG);
EEG = pop_epoch(EEG, {'dummy'}, [-1 3], 'epochinfo', 'yes');
EEG.setname = [baseName ' epochs'];

out = compute_spectopo_psd(EEG);
outFile = fullfile(outDir, sprintf('%s_%s_%s_alphaSNR.mat', pilotID, EEG.setname, montage));
save(outFile, 'out', 'EEG', 'pilotID');
end
