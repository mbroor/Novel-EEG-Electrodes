function setup_eeglab_paths()
% Paths for cleaned manuscript EEG code (same freeze settings as Aug 2026).

scriptDir  = fileparts(mfilename('fullpath'));
eeglabPath = '/Users/mishtibroor/Downloads/eeglab2026.0.0';
codePath   = scriptDir;  % local autoRejCh_func_CL.m

addpath(scriptDir, eeglabPath);
addpath(genpath(fullfile(eeglabPath, 'functions')));
addpath(genpath(fullfile(eeglabPath, 'plugins')));
eeglab('nogui');
end
