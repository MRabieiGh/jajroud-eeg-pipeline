if ~exist('dataDir', 'var')
    dataDir = uigetdir([], 'Path to Mat Data Folder');
    if ~exist('data', 'var')
        load(fullfile(dataDir, 'epochedData.mat'))
    end
end

monkeyName = strip(extract(...
    extract(dataDir, "Sessions\" + lettersPattern + "\"), ...
    "\" + lettersPattern + "\"), "\");
monkeyName = monkeyName{1};
sessionDate = strip(extract(dataDir, "\" + digitsPattern + "\"), "\");
sessionDate = sessionDate{1};
nSession = strip(extract(dataDir, "\S" + digitsPattern + "\"), "\");
nSession = nSession{1};

%
fs = 1000;
set(0, 'defaultTextInterpreter', 'latex')

%
wp      = [0.1, 1, 8, 13];
mags    = [0, 1, 0];
devs    = [0.05, 0.01, 0.05];
[n, Wn, beta, ftype] = kaiserord(wp, mags, devs, fs);
n       = n + rem(n,2);
b       = fir1(n, Wn, ftype, kaiser(n+1, beta), 'scale');

clear wp mags devs n Wn beta ftype

%
infoDir = ls(fullfile(dataDir, '..', '2021*'));
cmFile  = ls(fullfile(dataDir, '..', infoDir, '*-res.txt'));
cm = readmatrix(fullfile(dataDir, '..', infoDir, cmFile), ...
    'OutputType', 'string');
cm = extract(cm(:, 3), ("A"|("B"+("I"|"H"|"L")))+"_"+digitsPattern);
cmNum = str2double(extract(cm, digitsPattern));

stm.isSerieA        = strncmp(cm, 'A', 1);
stm.isSerieB        = strncmp(cm, 'B', 1);
stm.isHsf           = strncmp(cm, 'BH', 2);
stm.isIsf           = strncmp(cm, 'BI', 2);
stm.isLsf           = strncmp(cm, 'BL', 2);
stm.isHumanFace     = (stm.isSerieB & any(cmNum == 1:6, 2)) | ...
    (stm.isSerieA & any (cmNum == [1, 3, 5, 6, 7, 8, 9], 2));
stm.isAnimalFace    = (stm.isSerieB & any(cmNum == 7:9, 2)) | ...
    (stm.isSerieA & any (cmNum == 10:18, 2));

clear infoDir cmFile cm cmNum

% Results Directory
figDir = fullfile(dataDir, '..', 'Figures');
if ~isfolder(figDir)
    mkdir(figDir)
end

%% Face No-Face ERP
timeInd = 3000-100:3000+300;

figure('Units', 'centimeters', 'Position', [0, 0, 45, 21])
tl = tiledlayout('flow');
axList = [];
for iChannel = [5 7 9 13]
    axList = [axList, nexttile];
    x = filtfilt(b, 1, data(:, :, iChannel)')';
    g1 = mean(x(stm.isHumanFace, :), 1);
    g2 = mean(datasample(x(~stm.isHumanFace & ~stm.isAnimalFace, :), ...
        sum(stm.isHumanFace), 1, 'replace', false), 1);
    
    plot(time(timeInd), g1(timeInd), 'LineWidth', 3)
    hold on
    plot(time(timeInd), g2(timeInd), 'LineWidth', 3, ...
        'Color', [0.6350 0.0780 0.1840])
    title(strcat("Channel", " ", num2str(iChannel)))
end

linkaxes(axList)
yLim = ylim(axList(1));
for ax = axList
    plot(ax, [0, 0], yLim, 'k--', 'HandleVisibility', 'off')
    fill(ax, [150, 200, 200, 150], [yLim(1), yLim(1), yLim(2), yLim(2)], ...
        [0.5 0.5 0.5], 'FaceAlpha', .1, 'EdgeColor', 'none')
    legend(ax, 'Face', 'No-Face')
    xlabel(ax, 'time (ms)')
    ylabel(ax, 'Amplitude ($\mu$V)')
    xlim(ax, [-100, 300])
    set(ax, 'YGrid', 'on')
    xlabel(ax, 'time(ms)')
    ylabel(ax, 'Amplitude($\mu$V)')
    set(ax, 'FontSize', 12)
end
title(tl, "Event Related Potetntials")
subtitle(tl, strcat(monkeyName, " : ", sessionDate, " : ", nSession))
saveas(gcf, fullfile(figDir, "ERP-Face-NoFace.fig"))
saveas(gcf, fullfile(figDir, "ERP-Face-NoFace.png"))
close gcf
clear tl iChannel x timeInd g1 g2 ax axList yLim