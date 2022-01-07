%% SNr Thresholding
wp      = [0.1, 1, 8, 13];
mags    = [0, 1, 0];
devs    = [0.05, 0.01, 0.05];
[n, Wn, beta, ftype] = kaiserord(wp, mags, devs, fs);
n       = n + rem(n,2);
b       = fir1(n, Wn, ftype, kaiser(n+1, beta), 'scale');

clear wp mags devs n Wn beta ftype
channelSnr = nan(size(data, 3), 1);
for iChannel = 1:size(data, 3)
    x = data(:, :, iChannel);
    y = filtfilt(b, 1, x')';
    
    snrSum = 0;
    for iTrial = 1:size(data, 1)
        snrSum = snrSum + snr(x(iTrial, :), x(iTrial, :) - y(iTrial, :));
    end
    channelSnr(iChannel) = snrSum / size(data, 1);
end
clear snrSum channelSnr x y iTrial iChannel