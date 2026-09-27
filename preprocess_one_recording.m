function outFile = preprocess_one_recording(dataDir, vhdrFile, chRange, outDir, pilotID, montage)
% Clean one BrainVision recording and save its power spectrum. 
% Use for both rest and walk. Steps: load, high-pass, remove 60 Hz
% Drop bad channels, cut into 4 s pieces, compute the spectrum 

EEG = pop_loadbv(dataDir, vhdrFile, [], chRange); % load only the cap or novel channels
[~, baseName] = fileparts(vhdrFile);
EEG.setname = baseName;

EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'plotfreqz', 0); % 1 Hz high-pass to remove slow drift. EEGLAB chooses the other filter settings.
EEG = pop_cleanline(EEG, 'bandwidth', 2, 'chanlist', 1:EEG.nbchan, ...
    'linefreqs', 60, 'plotfigures', 0, 'scanforlines', 0, 'winsize', 4, 'winstep', 1); % remove 60 Hz electrical noise
EEG = autoRejCh_func_CL(EEG, 3); % drop a channel if its SD is more than 3 times the typical channel SD
EEG = pop_clean_rawdata(EEG, 'flatline_crit', 5, 'channel_criterion', 0.8, ...
    'line_noise_criterion', 'off', 'highpass', 'off', ...
    'burst_criterion', 'off', 'window_criterion', 'off'); % drop flat channels and channels that do not correlate with the others

% Cut the continuous recording into 4 s pieces
% The first piece starts 1s in, so the recording onset is not used
preSec = 1; epochSec = 4;
firstLat = preSec * EEG.srate + 1; % sample number where the first piece starts. 
nEpochs = floor((EEG.pnts - preSec * EEG.srate) / (epochSec * EEG.srate)); % how many full 4 s pieces fit
if nEpochs < 1, error('Recording too short for epochs.'); end
EEG.event = [];
for e = 1:nEpochs
    EEG.event(e).type = 'dummy'; % a marker so EEGLAB knows where each piece starts
    EEG.event(e).latency = firstLat + (e - 1) * epochSec * EEG.srate;
    EEG.event(e).duration = 0;
end
EEG = eeg_checkset(EEG);
EEG = pop_epoch(EEG, {'dummy'}, [-1 3], 'epochinfo', 'yes'); % 1 s before the marker to 3 s after = 4 s 
EEG.setname = [baseName ' epochs'];
 
out = compute_spectopo_psd(EEG); % power at each frequency
outFile = fullfile(outDir, sprintf('%s_%s_%s_alphaSNR.mat', pilotID, EEG.setname, montage));
save(outFile, 'out', 'EEG', 'pilotID');
end
