%% DEMORAD DATA

folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\pomiary0412\";
filename = "vitsin1m.bin";
fast_time_data_start = 50;
fast_time_data_end = [];
rangeCellMeters = [0.9 1.1];
skipSamples = 1e6*50;
readSamples = 1e6*40;
conjugated = 1;

% These parameter values as well as processing
% methods configuration can be defined in a separate object 
% with user-defined properties. Is it a good idea or better to keep
% it like it is?
% folder = "/home/user/Documents/praca_inz/matlab/old_measures_and_simulations/vital_signs/";
% filename = "breath.bin";
% fast_time_data_start = 50;
% fast_time_data_end = [];
% rangeCellMeters = [0.25 0.35];
% skipSamples = 1e6*0;
% readSamples = 1e6*10;
% conjugated = 1;

config_name = filename + ".conf";
filePath = folder + filename;
configPath = folder + config_name;

% read config
cfg = readConfigDemorad(configPath);

% read raw data - after this step, the procedure should be the same also
% for the phaser device
rawData = readRawDemorad(filePath, ...
    drcfg2signalInfo(cfg), ...
    "SkipSamples",skipSamples, ...
    "Samples",readSamples, ...
    "Conjugated",conjugated);

%% Pre-Processing and Display
% create range time map
rangeTimeMap = raw2rtm(rawData, ...
    "fast_time_data_start",fast_time_data_start, ...
    "fast_time_data_end",fast_time_data_end, ...
    "Window",'hann');

% extract slow time signal
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);

% extract phase in slow time
slowTimePhase = sts2stp(slowTimeSignal,"method","atan");

% demonstration
figure(1); slowTimePhase.plotPhase()
figure(2); rangeTimeMap.plotMap()
figure(3); rawData.plotIQ()


%% manually select range cell - later it will be auto-detection here
range_cell_of_choice = 0.28;
slowTimePhase.selectSingleCell(range_cell_of_choice);
slowTimeSignal.selectSingleCell(range_cell_of_choice);
figure(4); slowTimeSignal.plotSignal();
figure(5); slowTimePhase.plotPhaseDiff()

%% Perhaps some pre-processing (if needed)

% peaksFiltering
figure(10)
slowTimePhase = slowTimeSignal.removePhaseDiscontinuities("Display",1);
figure(40); slowTimeSignal.plotSignal();
figure(41); slowTimePhase.plotPhase();
figure(50); slowTimePhase.plotPhaseDiff();

% for now, we can skip resampling

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor();
pshe.process(slowTimePhase);
figure(111); pshe.plotHeartbeatSignal;
figure(121); pshe.plotStft;

%% FsstDecomposer
fsstDec = FsstDecomposer();
fsstDec.process(slowTimeSignal);
figure(21);plot(fsstDec.heartbeatEnvelope)






