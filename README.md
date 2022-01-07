# jajroud-eeg-pipeline
This pipeline assumes that recorded data are stored in the following format besides `.m` scripts:

| file name                       | file format | address                               | content                                     |
|---------------------------------|-------------|---------------------------------------|---------------------------------------------|
| *                               | .ns*        | */rootDir/                            | raw waveforms recorded from Cereplex Direct |
| *                               | .nev        | */rootDir/                            | serial io events                            |
| \<sessionDate\>-\<sessionTime\>-res | .txt        | */rootDir/"sessionDate"-"sessionTime" | sequence of presented stimuli               |

`rootDir` is a folder matching the following template: "*\Sessions\\<monkey name\>\\<session date\>\S\<session index\> (e.g. .\Fandoq\20211129\S01)

* Stage 1: Parsing Binary Data </br>
In this stage, using Blackrock's MATLAB toolkit (`NPMK`), event file (`.nev`) and timeseries (`.nsx`) are loaded into workspace.  </br>
In this stage, following procedure is applied: </br>
    1. A UI prompts asks the user to locate the session's root folder, in which the `.nev` ans `.nsx` files reside. User must assert that another folder named *sessionDate-sessionTime* containing trialInfo files exists within root directory.
    2. `NPMK`  reads event's timestamps and their corresponding values from NEV struct. These variables are saved in *Mat Data* folder created within root directory.
    3. For each of `.nsx` files, another mat file is generated inside *Mat Data* folder which contains raw channel data and their corresponding sampling frequency.
    4. Cleaning the workspace, sunch that only `dataDir` variable remains which will be used in second stage. `dataDir` is the path to *Mat Data* folder.

* Stage 2: Preprocessing </br>
In second stage, parsed data is filtered and other preprocessing methods are applied to it: </br>
    1. If `dataDir` did not exist in workspace, a UI prompt asks user to locate it.
    2. The script will load data files and triggers. For now, the script assumes that only one data file resides within `dataDir` and it'll raise an error otherwise.
    3. Based on data file's sampling frequency, decimating to 1kHz is applied using MATLAB's `decimate` function. For the purpose of least contamination to phase data, we'll apply zero-phase digital filter before downsampling by using 'iir' filter type in decimate function. To enhance numerical stability, downsampling from 30k (raw) data to final 1k data is performed in a 2 step procedure by first decimating by a factor of 3, then by a factor of 10.
    4. Next, the decimated data will go through a global detrending procedure in which every channel is subtracted from the least square line passing through its values. lsline is computed using MATLAB's `polyfit(x, y, 1)`.
    5. Then the data is notch filtered. Filter's specifications are listed below:
        | filter specification  | description                                            |
        |-----------------------|--------------------------------------------------------|
        | filter type (n)       | 6 (12 because it is applied both forward and backward) |
        | center frequency (f0) | 50Hz (0.1)                                             |
        | quality factor (q)    | 2.5                                                    |
        | design method         | butterworth                                            |
    6. The data is epoched based on events saved on data. each trial is assumed to be 10000 miliseconds, 2999 miliseconds prior to stimulus onset and 7000 miliseconds after that.
    7. Epoched data is saved insised `dataDir` under the name of *epochedData.mat*. Inside this file, epoched data (`data`), trial times aligned to onset (`time`) and `triggerValues` are stored.

* Stage 3: Event Related Potentials </br>
First stage in time-domain analysis:
    1. First we'll assert that `dataDir` and `data` variables exist in the workspace. If not, UI prompt asks user to locate *Mat Data* folder and loads *epochedData.mat*.
    2. Name of monkey, date of recording session and session index are loaded from `dataDir` address.
    3. a bandpass kaiser filter is used to extract data between 1-13 Hz. </br>
        | filter specification | description     |
        |----------------------|-----------------|
        | pass frequency       | [1, 8]          |
        | stop frequency       | [.1, 13]        |
        | magnitudes           | [0, 1, 0]       |
        | deviations           | [.05, .01. .05] |
    4. Stimulus conditioning is done based on the name of each image. First, stimuli set is divided into A series (intact dataset) and B series (spatial frequency dataset). Then, based on the stimulus series and the number corresponding to each image, categories (human face, animal face, ...) are separated.
    5. After equalizing number of conditions between two groups of interest using random sampling without replacement, evoked response is estimated using asynchronous averaging for each channel, resulting in a figure that is saved in *.\rootDir\Figures*.
