function chRange = channel_range_for_montage(pilotID, montage)
% Cap = left 1:16, Novel = right 17:32. Pilot005 hemispheres swapped.

if strcmp(pilotID, 'Pilot005')
    if strcmp(montage, 'CAP'), chRange = 17:32; else, chRange = 1:16; end
else
    if strcmp(montage, 'CAP'), chRange = 1:16; else, chRange = 17:32; end
end
end
