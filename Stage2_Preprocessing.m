if ~exist('dataDir', 'var')
    dataDir = uigetdir([], 'Path to Mat Data Folder');
end

% Load Triggers
load(fullfile(dataDir, 'triggers.mat'))

% Decimate RawDataFiles
dataFile = ls(fullfile(dataDir, 'rawData*.mat'));
assert(size(dataFile, 1) == 1)

load(fullfile(dataDir, dataFile))

if fs == 500
    error("Current pipeline only supports fs >= 1k")
elseif fs == 1000
    decimatedData = rawData';
elseif fs == 2000
    decimatedData = nan(ceil(size(rawData) ./ [1, 2]));
    for iChannel = 1:size(rawData, 1)
        decimatedData(iChannel, :) = decimate(rawData(iChannel, :), 2);
    end
elseif fs == 10000
    decimatedData = nan(ceil(size(rawData) ./ [1, 10]));
    for iChannel = 1:size(rawData, 1)
        decimatedData(iChannel, :) = decimate(rawData(iChannel, :), 10);
    end
elseif fs == 30000
    l = ceil(ceil(size(rawData, 2) / 3) / 10);
    decimatedData = nan(size(rawData, 1), l);
    for iChannel = 1:size(rawData, 1)
        tmp = decimate(rawData(iChannel, :), 3);
        decimatedData(iChannel, :) = decimate(tmp, 10);
    end
    clear l tmp
end
fs = 1000;
clear rawData iChannel dataFile

% Global Detrending
for iChannel = 1:size(decimatedData, 1)
    p = polyfit(1:size(decimatedData, 2), decimatedData(iChannel, :), 1);
    decimatedData(iChannel, :) = decimatedData(iChannel, :) - ...
        p(1) * (1:size(decimatedData, 2)) - p(2);
end
clear p iChannel

% Filtering Data
d = fdesign.notch(6, 50/500, 2.5);
Hd1 = design(d);

filteredData = nan(size(decimatedData));
for iChannel = 1:size(decimatedData, 1)
    filteredData(iChannel, :) = filtfilt(Hd1.sosMatrix, Hd1.ScaleValues, ...
        decimatedData(iChannel, :));
end
clear decimatedData d Hd1 iChannel

% Epoching
preOnsetSamples = 3000 - 1;
postOnsetSamples = 7000;
time = -preOnsetSamples:postOnsetSamples;

data = nan(length(triggerTimes), preOnsetSamples + postOnsetSamples+ 1, ...
    size(filteredData, 1));
for iTrial = 1:size(data, 1)
    os = round(triggerTimes(iTrial) / 30);
    data(iTrial, :, :) = filteredData(:, os-preOnsetSamples:os+postOnsetSamples)';
end
clear iTrial filteredData postOnsetSamples preOnsetSamples os triggerTimes
clear nTrialSample 

% Saving Results
save(fullfile(dataDir, 'epochedData'), 'triggerValues', 'data', 'time');