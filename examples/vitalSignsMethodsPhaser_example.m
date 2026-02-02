folder = "C:\Users\bfalecki\Documents\challenge\rec\";
% folder = "/home/user/Documents/praca_mgr/measurements/phaser/";

filename = "phaser_rec_04-Dec-2025_18-23-11_vs0.5m.mat";
range_cell = 0.3; % meters

% filename = "phaser_rec_04-Dec-2025_18-39-31_vs1m.mat";
% range_cell = 1; % meters

% filename = "phaser_rec_04-Dec-2025_18-46-23_vs2m.mat";
% range_cell = 2; % meters

rangeCellMeters = [0.25 2.5];

rawData = readRawPhaser(folder+filename,"lengthSeconds",120,"offsetSeconds",40);

%%
figure(1); rawData.plotIQ()
figure(2); rawData.plotMatrix()

%% 
rangeTimeMap = raw2rtm(rawData,"fast_time_data_start",1, "fast_time_data_end",2045,"Window","hann");
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);
slowTimeSignal.selectSingleCell(range_cell);
slowTimePhase = sts2stp(slowTimeSignal,"method","atan");


figure(3); slowTimeSignal.plotSignal()
figure(4); slowTimePhase.plotPhase()
figure(5); slowTimePhase.plotPhaseDiff()


%% preprocessing
figure(6); slowTimePhase = slowTimeSignal.removePhaseDiscontinuities("Display",1);

%% Breath rate extraction
tfa0 = TimeFreqAnalyzer("WindowWidth",10,"FrequencyResolution",1/60/4,"MaximumVisibleFrequency",1);
tfa0.transform(slowTimePhase)
tfa0.detectRidge( ...
    "NuberOfRidges",1, ...
    "SelectMethod","first", ...
    "JumpPenalty",2, ...
    "PossibleHighFrequency",0.8,  "PossibleLowFrequency",0.05)
figure(7); tfa0.plotResults("QuantileVal",0.8,"AllRidges",1)

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor("heartOscillationFreqRange",[5 15], ...
    "frequencyResolution",0.5, ...
    "phaseCutoffFreqLow",5, ...
    "windowWidth",0.25);
pshe.process(slowTimePhase);
figure(111); pshe.plotHeartbeatSignal;
figure(121); pshe.plotStft;

%% BandPassHeartbeatExtractor
bphe = BandPassHeartbeatExtractor("PassBand",[0.8 1.8]);
bphe.process(slowTimePhase)
figure(991); bphe.plotResult()

%% Combined BandPassHeartbeatExtractor and PhaseStftHearbeatExtractor

rc = ResultsCombiner();
% rc.combine(bphe, pshe,"timeDelay2",0.15, "weights",[-1, 1]);
rc.combine(bphe, pshe,"estimateDelay",1,"estimateSign",0, "weights",[1, 1]);

figure(191); rc.plotEstimatedDelay()
figure(192); rc.plotResult()

% % prediction in breaks
% [start_samples ,end_samples]= rc.getSegmentsStartsEnds();
% segments_idxes = get_segments_idxes(start_samples,end_samples, length(rc.getSignal));
% rc.combinedSignal  = fill_gaps_ar_wrapped(rc.combinedSignal ,...
%     rc.getSamplingFrequency,segments_idxes ,rc.ttfa1.slowTimePhase.segmentDuration,"PartConsidered",0);

% % envelope normalization
% normWindow = 2; % seconds
% windowWidth = round(normWindow*rc.getSamplingFrequency);
% combinedSignalEnvelopeNorm = normalizeEnvelope(rc.combinedSignal,windowWidth);
% rc.combinedSignal = combinedSignalEnvelopeNorm;

%% Inter-beat interval estimation
[start_samples,end_samples] =  rc.getSegmentsStartsEnds;
ibi = estimateIbi(combinedSignalEnvelopeNorm, rc.getSamplingFrequency, ...
    "StartSamples",start_samples, ...
    "EndSamples",end_samples, ...
    "EroseSize",0);

%% Time-Frequency Analysis
tfAnalyzables = {pshe,bphe, rc};
tfaVect = {};
fig_nr = [1211 992 193];

for k = 1:length(tfAnalyzables)
    tfaVect{k} = TimeFreqAnalyzer( ...
        "WindowWidth",10, ...
        "FrequencyResolution",0.2/60, ...
        "MaximumVisibleFrequency",150/60, ...
        "Synchrosqueezed",0);
    tfaVect{k}.transform(tfAnalyzables{k})
    % find time-frequency ridge with memory
    tfaVect{k}.detectRidge( ...
    "NuberOfRidges",3, ...
    "PossibleLowFrequency",40/60,...
    "PossibleHighFrequency",150/60,...
    "JumpPenalty",0.01, ...
    "SelectMethod","first", ... "lowest" / "first" / "nearest" / "middle"
    "DesiredNearestFrequency", 80/60 ...
    );
    % find time-frequency ridge without memory
    frequencyDistanceToHarmonics = 1/mean(diff(slowTimeSignal.signalInfo.frameStartTimes)); % frame-length dependent
    tfaVect{k}.detectPeaks( ...
        "Method", "distanceBased", ...  "highest" / "lower" / "middle" / "distanceBased"
        "ExactDistance",frequencyDistanceToHarmonics, ...
        "DistanceTolerance",0.05 * frequencyDistanceToHarmonics ...
        );
    figure(fig_nr(k));
    tfaVect{k}.plotResults( ...
        "QuantileVal",0.5,"AllRidges",1, "PlotRidges",1,"PlotPeaks",1,"PlotPeaksHarmonics",1)
end

%% Comparison with Reference: RMSE with Memory ------- 
referencePath = "C:\Users\bfalecki\Documents\challenge\reference\kalenji\2025-12-04.fit";
hre = HeartRateReference(referencePath,"ManualTimeShift",1-5/3600);
cellfun(@(x) x.setHeartRateOutput("ridge"),tfaVect)
errors = hre.calucateError(tfaVect);
figure(10101);hre.plot("otherResults",tfaVect, "showAdjusted",1)
disp("RMSE with memory in BPM: " + join(string(errors)))

%% Comparison with Reference: RMSE without Memory - - -  -
cellfun(@(x) x.setHeartRateOutput("peaks"),tfaVect)
errors_nomemory =  hre.calucateError(tfaVect);
figure(10102);hre.plot("otherResults",tfaVect)
disp("RMSE without memory in BPM: " + join(string(errors_nomemory)))
