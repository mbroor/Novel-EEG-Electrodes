function setup_eeglab_paths()
% Add this script folder and EEGLAB to the MATLAB path, then start EEGLAB without a window.

scriptDir  = fileparts(mfilename('fullpath'));          % folder that contains these scripts
eeglabPath = '/path/to/eeglab';                         % change this to your EEGLAB folder before running

addpath(scriptDir, eeglabPath);                         
addpath(genpath(fullfile(eeglabPath, 'functions')));    % EEGLAB functions
addpath(genpath(fullfile(eeglabPath, 'plugins')));      % CleanLine, clean_rawdata, and the other plugins
eeglab('nogui');                                        % start EEGLAB with no windows
end  
