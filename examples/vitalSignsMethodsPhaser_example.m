% folder = "C:\Users\bfalecki\Documents\challenge\rec\";
folder = "/home/user/Documents/praca_mgr/measurements/phaser/";

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
fa = FsstAnalyzer("WindowWidth",10,"FrequencyResolution",1/60/4,"MaximumVisibleFrequency",1);
fa.transform(slowTimePhase)
fa.detectRidge( ...
    "NuberOfRidges",1, ...
    "SelectMethod","first", ...
    "JumpPenalty",2, ...
    "PossibleHighFrequency",0.8,  "PossibleLowFrequency",0.05)
figure(7); fa.plotResults("QuantileVal",0.8,"AllRidges",1)

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor("heartOscillationFreqRange",[5 15], ...
    "frequencyResolution",0.5, ...
    "phaseCutoffFreqLow",5, ...
    "windowWidth",0.25);
pshe.process(slowTimePhase);
figure(111); pshe.plotHeartbeatSignal;
figure(121); pshe.plotStft;

fa = FsstAnalyzer("WindowWidth",10,"FrequencyResolution",0.2/60,"MaximumVisibleFrequency",150/60);
fa.transform(pshe)
fa.detectRidge( ...
    "NuberOfRidges",3, ...
    "PossibleLowFrequency",40/60,...
    "PossibleHighFrequency",150/60,...
    "JumpPenalty",1, ...
    "SelectMethod","middle", ...
    "DesiredNearestFrequency", 80/60 ...
    );

figure(1211); fa.plotResults("QuantileVal",0.5,"AllRidges",1, "PlotRidges",1)

%% Now some state-of-the-art method
% DWT / VMD
% https://chatgpt.com/share/696e5c6a-26f8-8003-9113-10526495736b

%% BandPassHeartbeatExtractor
bphe = BandPassHeartbeatExtractor("PassBand",[0.8 1.8]);
bphe.process(slowTimePhase)
figure(991); bphe.plotResult()

fa1 = FsstAnalyzer("WindowWidth",10,"FrequencyResolution",0.2/60,"MaximumVisibleFrequency",150/60);
fa1.transform(bphe)
fa1.detectRidge( ...
    "NuberOfRidges",3, ...
    "PossibleLowFrequency",40/60,...
    "PossibleHighFrequency",150/60,...
    "JumpPenalty",1, ...
    "SelectMethod","middle", ...
    "DesiredNearestFrequency", 80/60 ...
    );
figure(992); fa1.plotResults("QuantileVal",0.5,"AllRidges",1, "PlotRidges",1)

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
%     rc.getSamplingFrequency,segments_idxes ,rc.tfa1.slowTimePhase.segmentDuration,"PartConsidered",0);

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

%%
fa12 = FsstAnalyzer("WindowWidth",10,"FrequencyResolution",0.2/60,"MaximumVisibleFrequency",150/60);
fa12.transform(rc)
fa12.detectRidge( ...
    "NuberOfRidges",3, ...
    "PossibleLowFrequency",40/60,...
    "PossibleHighFrequency",150/60,...
    "JumpPenalty",1, ...
    "SelectMethod","middle", ...
    "DesiredNearestFrequency", 80/60 ...
    );
figure(193); fa12.plotResults("QuantileVal",0.5,"AllRidges",1, "PlotRidges",1)


%% check result without tfridge memory
% [~, locs12] = findMiddlePeak(abs(fa12.tfdistribution));
% [~, locs1] = findMiddlePeak(abs(fa1.tfdistribution));
% [~, locs] = findMiddlePeak(abs(fa.tfdistribution));
% [~, locs12] = findLowerPeak(abs(fa12.tfdistribution));
% [~, locs1] = findLowerPeak(abs(fa1.tfdistribution));
% [~, locs] = findLowerPeak(abs(fa.tfdistribution));
% [~, locs12] = findHighestPeak(abs(fa12.tfdistribution));
% [~, locs1] = findHighestPeak(abs(fa1.tfdistribution));
% [~, locs] = findHighestPeak(abs(fa.tfdistribution));
freq_step_size = fa.f_ax(2) - fa.f_ax(1);
distance = round(19.5/60/freq_step_size);
distTolerance = 5;
[~,locs, upper_locs, lower_locs] = findOptimumPeak(abs(fa.tfdistribution),distance, distTolerance);
[~,locs1, upper_locs, lower_locs] = findOptimumPeak(abs(fa1.tfdistribution),distance, distTolerance);
[~,locs12, upper_locs, lower_locs] = findOptimumPeak(abs(fa12.tfdistribution),distance, distTolerance);
locs12 = fillmissing(locs12, "nearest");
locs1 = fillmissing(locs1, "nearest");
locs = fillmissing(locs, "nearest");
figure(199); 
plot(fa1.f_ax(locs1)*60, 'r')
hold on
plot(fa.f_ax(locs)*60, 'k')
plot(fa12.f_ax(locs12)*60, 'b', LineWidth=2)
hold off

%% Comparison with Reference: RMSE with Memory ------- 
referencePath = "C:\Users\bfalecki\Documents\challenge\reference\kalenji\2025-12-04.fit";
hre = HeartRateReference(referencePath,"ManualTimeShift",1-5/3600);
figure(999);hre.plot("otherResults",[fa fa1 fa12])
errors = hre.calucateError([fa fa1 fa12]);
disp("RMSE with memory in BPM: " + join(string(errors)))

%% Comparison with Reference: RMSE without Memory - - -  -
fa.ridge = fa.f_ax(locs);
fa1.ridge = fa1.f_ax(locs1);
fa12.ridge = fa12.f_ax(locs12);
errors_nomemory =  hre.calucateError([fa fa1 fa12]);
disp("RMSE without memory in BPM: " + join(string(errors_nomemory)))
