%% Phaser
filePath = "C:\Users\bfalecki\Documents\challenge\rec\phaser_rec_04-Dec-2025_18-39-31_vs1m.mat";
lengthSeconds = 40;
offsetSeconds = 60;
fast_time_data_start = [];
fast_time_data_end = [];
window = 'hann';
rangeCellMeters = [0.6 1.5];
fixEdgesDepth = 0.1;

% read raw data
rawData = readRawPhaser(filePath, ...
    "lengthSeconds",lengthSeconds, ...
    "offsetSeconds",offsetSeconds);
% create range time map
rangeTimeMap = raw2rtm(rawData, ...
    "fast_time_data_start",fast_time_data_start, ...
    "fast_time_data_end",fast_time_data_end, ...
    "Window",window);

% extract slow time signal
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);

% extract phase in slow time
slowTimePhase = sts2stp(slowTimeSignal, ...
    "method","atan", ...
    "fixEdgesDepth",fixEdgesDepth);

% demonstration
figure(1); plot(slowTimePhase.phase.'); legend(string(slowTimePhase.actualRangeCellsMeters) + " m")

%% Select the best range cell manually (later it will be auto-detection here)
desiredRangeCell = 0.9;
slowTimePhase.selectSingleCell(desiredRangeCell)

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor();
pshe.process(slowTimePhase)
figure(2); pshe.plotHeartbeatSignal()
figure(3); pshe.plotStft()

%% FsstDecomposer
fsstDec = FsstDecomposer();