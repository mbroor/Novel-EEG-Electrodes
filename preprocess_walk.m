%% Walk preprocess + spectopo PSD (cleaned). Same pipeline as rest (CPz, no re-ref).
% File list: matlab/filelists/walk_recordings.csv
% Note: Pilot008 is in this list for completeness; exclude in FOOOF stats (n=18).

clear; clc; rng(1, 'twister');
setup_eeglab_paths;

rawRoot = '/Users/mishtibroor/Desktop/LAB DATA/Data Collection /';  % trailing space required
outRoot = '/Users/mishtibroor/Desktop/Preprocessed Data (matlab)/Phase1_clean';
listCsv = fullfile(fileparts(mfilename('fullpath')), 'walk_recordings.csv');
T = readtable(listCsv, 'TextType', 'string');
nJobs = height(T);
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

fprintf('DONE walk. Success %d / %d  Fail %d / %d\n', nOk, nJobs, nFail, nJobs);
