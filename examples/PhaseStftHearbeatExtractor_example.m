%% load data in slow time
filePath = "C:\Users\bfalecki\Documents\challenge\rec\phaser_rec_04-Dec-2025_18-39-31_vs1m.mat";
% read raw data
rawData = readRawPhaser(filePath,"lengthSeconds",40,"offsetSeconds",60);
% create range time map
rangeTimeMap = raw2rtm(rawData,"fast_time_data_start",[], "fast_time_data_end",[],"Window",'hann');

% extract slow time signal
rangeCellMeters = [0.6];
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);

% extract phase in slow time
slowTimePhase = sts2stp(slowTimeSignal,"method","atan","fixEdgesDepth",0.1);

% demonstration
figure(1); plot(slowTimePhase.phase.'); legend(string(slowTimePhase.actualRangeCellsMeters) + " m")
%% run processing
pshe = PhaseStftHearbeatExtractor(); % default parameters
pshe.process(slowTimePhase);
figure(2); pshe.plotHeartbeatSignal()
figure(3); pshe.plotStft()