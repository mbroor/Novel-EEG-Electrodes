%% Resting EEG -> turn each raw recording into a power spectrum.
% Each row of rest_recordings.csv is one recording
% Cap = ch 1:16, Novel 17:32 (Pilot005 swapped). Reference stays CPz.

clear; clc; rng(1, 'twister'); % start clean; lock the random seed so reruns match
setup_eeglab_paths; 


% Change these two folders before running. They will be different on every computer.
rawRoot = '/path/to/raw_brainvision_data';  % folder that contains the original .vhdr recordings
outRoot = '/path/to/output_psd';            % folder where the spectrum .mat files should be saved
listCsv = fullfile(fileparts(mfilename('fullpath')), 'rest_recordings.csv');  % file list kept next to this script

T = readtable(listCsv, 'TextType', 'string');
nJobs = height(T); % number of recordings are in the list
nOk = 0; nFail = 0; 

for i = 1:nJobs
    pilotID  = char(T.pilotID(i)); 
    dataDir  = fullfile(rawRoot, char(T.eeg_folder(i)));
    montage  = char(T.montage(i));
    vhdrFile = char(T.vhdr(i));
    outDir   = fullfile(outRoot, pilotID);
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    chRange = channel_range_for_montage(pilotID, montage);
    fprintf('[%d/%d] %s | %s | %s\n', i, nJobs, pilotID, montage, vhdrFile);
    try
        outFile = preprocess_one_recording(dataDir, vhdrFile, chRange, outDir, pilotID, montage);
        S = load(outFile, 'out');
        fprintf('  OK %d ch\n', size(S.out.psd_all, 1));
        nOk = nOk + 1;
    catch ME
        nFail = nFail + 1;
        fprintf(2, '  FAIL: %s\n', ME.message);
    end
end

fprintf('DONE rest. Success %d / %d  Fail %d / %d\n', nOk, nJobs, nFail, nJobs);
