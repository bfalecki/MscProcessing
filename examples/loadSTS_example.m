%% Demorad: load slow time signal / slow time phase of a single range cell

% data file and config file localization
folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\pomiary0412\";
filename = "vitsin1m.bin";
SkipSamples = 1e6*60;
Samples = 1e6*40;
fast_time_data_start = 50;
fast_time_data_end = [];
window = 'hann';
rangeCellMeters = [0.9 1.1];
Conjugated = 0;

config_name = filename + ".conf";
filePath = folder + filename;
configPath = folder + config_name;

% read config
cfg = readConfigDemorad(configPath);

% read raw data - after this step, the procedure should be the same also
% for the phaser device
rawData = readRawDemorad(filePath, ...
    drcfg2signalInfo(cfg), ...
    "SkipSamples",SkipSamples, ...
    "Samples",Samples, ...
    "Conjugated", Conjugated);

% create range time map
rangeTimeMap = raw2rtm(rawData, ...
    "fast_time_data_start",fast_time_data_start, ...
    "fast_time_data_end",fast_time_data_end, ...
    "Window",window);

% extract slow time signal
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);

% extract phase in slow time
slowTimePhase = sts2stp(slowTimeSignal,"method","atan");

% demonstration
figure(111); rawData.plotMatrix();
figure(112); rawData.plotIQ();
figure(12); rangeTimeMap.plotMap();
figure(13); slowTimeSignal.plotSignal();
figure(14); slowTimePhase.plotPhase();

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
slowTimePhase = sts2stp(slowTimeSignal,"method","atan","fixEdgesDepth",fixEdgesDepth);

% demonstration
figure(211); rawData.plotMatrix();
figure(212); rawData.plotIQ();
figure(22); rangeTimeMap.plotMap();
figure(23); slowTimeSignal.plotSignal();
figure(24); slowTimePhase.plotPhase();