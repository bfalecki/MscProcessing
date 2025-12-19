%% Demorad: load slow time signal / slow time phase of a single range cell

% data file and config file localization
folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\pomiary0412\";
filename = "vitsin1m.bin";
config_name = filename + ".conf";
filePath = folder + filename;
configPath = folder + config_name;

% read config
cfg = readConfigDemorad(configPath);

% read raw data - after this step, the procedure should be the same also
% for the phaser device
rawData = readRawDemorad(filePath,drcfg2signalInfo(cfg),"SkipSamples",1e6*60, "Samples",1e6*40);

% create range time map
rangeTimeMap = raw2rtm(rawData,"fast_time_data_start",50, "fast_time_data_end",[],"Window",'hann');

% extract slow time signal
rangeCellMeters = [0.9 1.1];
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);

% extract phase in slow time
slowTimePhase = sts2stp(slowTimeSignal,"method","atan");

% demonstration
figure(2); plot(slowTimePhase.phase.'); legend(string(slowTimePhase.actualRangeCellsMeters) + " m")

%% Phaser
filePath = "C:\Users\bfalecki\Documents\challenge\rec\phaser_rec_04-Dec-2025_18-39-31_vs1m.mat";
% read raw data
rawData = readRawPhaser(filePath,"lengthSeconds",40,"offsetSeconds",60);
% create range time map
rangeTimeMap = raw2rtm(rawData,"fast_time_data_start",[], "fast_time_data_end",[],"Window",'hann');

% extract slow time signal
rangeCellMeters = [0.6 1.5];
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);

% extract phase in slow time
slowTimePhase = sts2stp(slowTimeSignal,"method","atan","fixEdgesDepth",0.1);

% demonstration
figure(1); plot(slowTimePhase.phase.'); legend(string(slowTimePhase.actualRangeCellsMeters) + " m")