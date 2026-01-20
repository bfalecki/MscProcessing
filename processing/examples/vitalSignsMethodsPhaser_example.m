folder = "C:\Users\bfalecki\Documents\challenge\rec\";
filename = "phaser_rec_04-Dec-2025_18-23-11_vs0.5m.mat";
rangeCellMeters = [0.25 1];

rawData = readRawPhaser(folder+filename,"lengthSeconds",30,"offsetSeconds",40);

%%
figure(1); rawData.plotIQ()
figure(2); rawData.plotMatrix()

%% 
rangeTimeMap = raw2rtm(rawData,"fast_time_data_start",1, "fast_time_data_end",2045,"Window","hann");
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);
slowTimeSignal.selectSingleCell(0.3);
slowTimePhase = sts2stp(slowTimeSignal,"method","atan");


figure(3); slowTimeSignal.plotSignal()
figure(4); slowTimePhase.plotPhase()
figure(5); slowTimePhase.plotPhaseDiff()


%% preprocessing
figure(6); slowTimePhase = slowTimeSignal.removePhaseDiscontinuities("Display",1);

%% Breath rate extraction
fa = FsstAnalyzer("WindowWidth",10,"FrequencyResolution",1/60/4,"MaximumVisibleFrequency",1);
fa.transform(slowTimePhase)
fa.detectRidge( ...
    "NuberOfRidges",1, ...
    "SelectMethod","first", ...
    "JumpPenalty",2, ...
    "PossibleHighFrequency",0.8,  "PossibleLowFrequency",0.05)
figure(7); fa.plotResults("QuantileVal",0.8,"AllRidges",1)

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor();
pshe.process(slowTimePhase);
figure(111); pshe.plotHeartbeatSignal;
figure(121); pshe.plotStft;

fa = FsstAnalyzer("WindowWidth",5);
fa.transform(pshe)
fa.detectRidge( ...
    "NuberOfRidges",3, ...
    "SelectMethod","first", ...
    "JumpPenalty",20)
figure(1211); fa.plotResults("QuantileVal",0.5,"AllRidges",1)

%% Now some state-of-the-art method
% DWT / VMD
% https://chatgpt.com/share/696e5c6a-26f8-8003-9113-10526495736b

%% BandPassHeartbeatExtractor
bphe = BandPassHeartbeatExtractor("PassBand",[0.8 1.5]);
bphe.process(slowTimePhase)
figure(991); bphe.plotResult()

fa = FsstAnalyzer("WindowWidth",5);
fa.transform(bphe)
fa.detectRidge( ...
    "NuberOfRidges",3, ...
    "SelectMethod","first", ...
    "JumpPenalty",20)
figure(992); fa.plotResults("QuantileVal",0.5,"AllRidges",1)

%% Reference
