function [pupilarea, TFblink] = ppl(daq, pupildata, timsec)

pupil_y = zeros(1,length(pupildata));
pupil_x = linspace(0, daq.timev(end), length(pupildata));
blink = zeros(1,length(pupildata));
    
for j = 1:length(pupildata)
    pupil_y(j) = pi * ((((pupildata(j,11) - pupildata(j,14)).^2 + (pupildata(j,12) - pupildata(j,15)).^2).^0.5) / 2) * ((((pupildata(j,8) - pupildata(j,17)).^2 + (pupildata(j,9) - pupildata(j,18)).^2).^0.5) / 2);
    blink(j) = ((pupildata(j,2) - pupildata(j,5)).^2 + (pupildata(j,3) - pupildata(j,6)).^2).^0.5;
end


%pupil resample
pupilarea = zeros(1,length(timsec));
blink_resample = zeros(1,length(timsec));

for j = 1:length(timsec)
    [~, pupil_y_index] = min(abs(pupil_x - timsec(j)));
    pupilarea(j) = pupil_y(pupil_y_index);
    blink_resample(j) = blink(pupil_y_index);
end

std_blink = std(blink_resample);
mean_blink = mean(blink_resample);
TFblink = blink_resample < mean_blink -std_blink*3;