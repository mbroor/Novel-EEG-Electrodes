function [EEG_out, Total_rej] = autoRejCh_func_CL(EEG, thres)
% Reject channels with SD > thres × median SD (Liu lab). Default thres = 3.

EEG_chans   = find(strcmpi('EEG',   {EEG.chanlocs.type})); % EEG Channel numbers
Noise_chans = find(strcmpi('Noise', {EEG.chanlocs.type})); % noise-reference channel numbers
EMG_chans   = find(strcmpi('EMG',   {EEG.chanlocs.type})); % EMG channel numbers

EEG_SD   = std(EEG.data(EEG_chans, :)'); 
EMG_SD   = std(EEG.data(EMG_chans, :)');
Noise_SD = std(EEG.data(Noise_chans, :)');

badEEGch   = EEG_chans(find(EEG_SD   > thres * median(EEG_SD))); % EEG Channels noisier than 3 x the typical EEG channel
badEMGch   = EMG_chans(find(EMG_SD   > thres * median(EMG_SD)));
badNoiseCh = Noise_chans(find(Noise_SD > thres * median(Noise_SD)));

fprintf('Reject EEG %s | EMG %s | Noise %s\n', ...
    num2str(badEEGch), num2str(badEMGch), num2str(badNoiseCh)); % print which channels were dropped

EEG_out = pop_select(EEG, 'nochannel', sort(unique([badEEGch, badEMGch, badNoiseCh]))); % remove those channels
Total_rej = [length(badEEGch), length(badEMGch), length(badNoiseCh)]; % how many of each type were removed
end
