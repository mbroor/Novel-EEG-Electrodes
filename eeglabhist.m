% EEGLAB history file generated on the 02-Jun-2026
% ------------------------------------------------
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
EEG = pop_loadbv('/Users/mishtibroor/Desktop/LAB DATA/LiveAmp/PILOT_009/', 'Pilot_009_cap_rest_eyeopen.vhdr', [1 90110], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16]);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname','cap_eyeopen','gui','off'); 
EEG = pop_eegfiltnew(EEG, 'locutoff',1,'chantype',{'EEG'}); %1 Hz HP filter (results in -6bB cutoff at 0.5 Hz)


[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
EEG = pop_cleanline(EEG, 'bandwidth',2,'chanlist',[1:16] ,'computepower',1,'linefreqs',60,'newversion',0,'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',0,'sigtype','Channels','taperbandwidth',2,'tau',100,'verb',1,'winsize',4,'winstep',1);
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 


EEG = autoRejCh_func_CL(EEG,3);

pop_eegplot( EEG, 1, 1, 1);
eeglab redraw;
