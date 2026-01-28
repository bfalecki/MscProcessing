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
figure(911); rawData.plotMatrix();
figure(912); rawData.plotIQ();
figure(92); rangeTimeMap.plotMap();
figure(93); slowTimeSignal.plotSignal();
figure(94); slowTimePhase.plotPhase();

%% Select the best range cell manually (later it will be auto-detection here)
desiredRangeCell = 1;
slowTimePhase.selectSingleCell(desiredRangeCell)
slowTimeSignal.selectSingleCell(desiredRangeCell)

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor();
pshe.process(slowTimePhase)
figure(11); pshe.plotHeartbeatSignal()
figure(12); pshe.plotStft()

%% FsstDecomposer
fsstDec = FsstDecomposer();