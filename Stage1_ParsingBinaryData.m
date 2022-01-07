close all
clear
clc

% Add Path
addpath(genpath('NPMK'))

% Get Data Root Folder
dataDir = uigetdir();

% Create Save Directory
saveDir = fullfile(dataDir, 'Mat Data');
if ~isfolder(saveDir)
    mkdir(saveDir)
end

% Save Events
eventFile = ls(fullfile(dataDir, '*.nev'));
openNEV('read', fullfile(dataDir, eventFile), ...
    'report', 'uV', 'nomat', 'nosave', '8bits');

triggerTimes = NEV.Data.SerialDigitalIO.TimeStamp;
triggerValues = NEV.Data.SerialDigitalIO.UnparsedData;

save(fullfile(saveDir, 'triggers.mat'), ...
    'triggerTimes', 'triggerValues')

clear NEV triggerTimes triggerValues eventFile

% Save Raw Data
for iFs = 1:6
    rawFile = ls(fullfile(dataDir, strcat('*.ns', num2str(iFs))));
    
    if isempty(rawFile)
        continue
    end
    
    assert(size(rawFile, 1) == 1)
    
    NS = openNSx('read', fullfile(dataDir, rawFile), 'report', 'uV');
    rawData = NS.Data;
    fs = NS.MetaTags.SamplingFreq;
    
    save(fullfile(saveDir, strcat('rawData', num2str(fs), '.mat')), ...
        'rawData', 'fs', '-v7.3');
end
clear rawData fs NS iFs rawFile

% Clean Up Workspace
dataDir = saveDir;
clear saveDir;