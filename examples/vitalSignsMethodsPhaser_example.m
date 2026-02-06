% folder = "C:\Users\bfalecki\Documents\challenge\rec\";
folder = "/home/user/Documents/praca_mgr/measurements/phaser/";

filename = "phaser_rec_04-Dec-2025_18-23-11_vs0.5m.mat";
range_cell = 0.3; % meters

% filename = "phaser_rec_04-Dec-2025_18-39-31_vs1m.mat";
% range_cell = 1; % meters

% filename = "phaser_rec_04-Dec-2025_18-46-23_vs2m.mat";
% range_cell = 2; % meters

rangeCellMeters = [0.25 2.5];

lengthSeconds = 180;
offsetSeconds = 30;
rawData = readRawPhaser(folder+filename,"lengthSeconds",lengthSeconds,"offsetSeconds",offsetSeconds);
loadConfig = SignalLoadingConfig(lengthSeconds,offsetSeconds,filename);

%%
% figure(1); rawData.plotIQ()
% figure(2); rawData.plotMatrix()

%% 

fast_time_data_start = 1;
fast_time_data_end = 2045;
FastTimeWindow = "hann";
rangeTimeMap = raw2rtm(rawData,"fast_time_data_start",fast_time_data_start, "fast_time_data_end",fast_time_data_end,"Window",FastTimeWindow);
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);
slowTimeSignal.selectSingleCell(range_cell);
phaseUnwrappingMethod = "atan";
% slowTimePhase = sts2stp(slowTimeSignal,"method",phaseUnwrappingMethod);

%% preprocessing
figure(6); [slowTimePhase, phaseDiscontCompParams] = slowTimeSignal.removePhaseDiscontinuities("Display",1,"ThresholdMultiplier",5);
preprocConfig = PreprocessingConfig(range_cell,fast_time_data_start,fast_time_data_end,FastTimeWindow,phaseUnwrappingMethod,phaseDiscontCompParams);

slowTimePhase.removeLinearPhase()

figure(3); slowTimeSignal.plotSignal()
figure(4); slowTimePhase.plotPhase()
figure(5); slowTimePhase.plotPhaseDiff()

%% optional save pre-processed signal to file
preprocDir = "data" + filesep;
filepathPreprocessed = makeOutputFilename(filename, "preproc", preprocDir, "extension",".mat");
save(filepathPreprocessed, "slowTimeSignal","slowTimePhase","loadConfig","preprocConfig")

%% optional read pre-processed signal from file
% filepathPreprocessed = "data"+filesep+"phaser_rec_04-Dec-2025_18-23-11_vs0.5m__preproc.mat";
% filepathPreprocessed = "data"+filesep+"phaser_rec_04-Dec-2025_18-39-31_vs1m__preproc.mat";
filepathPreprocessed = "data"+filesep+"phaser_rec_04-Dec-2025_18-46-23_vs2m__preproc.mat";

preprocFile = load(filepathPreprocessed);
loadConfig = preprocFile.loadConfig;
preprocConfig = preprocFile.preprocConfig;
slowTimePhase =  preprocFile.slowTimePhase;
slowTimeSignal =  preprocFile.slowTimeSignal;


%% Breath rate extraction
bpbe = BandPassBreathExtractor("PassBand",[0.1 0.8],"UpsamplingFactor",4);
bpbe.process(slowTimePhase)
figure(311)
bpbe.plotResult

tfa0 = TimeFreqAnalyzer("WindowWidth",15,"FrequencyResolution",1/60/4,"MaximumVisibleFrequency",1,"Synchrosqueezed",0);
tfa0.transform(slowTimePhase)
tfa0.detectRidge( ...
    "NuberOfRidges",1, ...
    "SelectMethod","first", ...
    "JumpPenalty",1, ...
    "PossibleHighFrequency",0.8,  "PossibleLowFrequency",0.1)
figure(312); tfa0.plotResults("QuantileVal",0.8,"AllRidges",1,"PlotPeaks",0)

%% PhaseStftHearbeatExtractor
pshe = PhaseStftHearbeatExtractor("heartOscillationFreqRange", [0 40], ...
    "frequencyResolution",0.5, ...
    "phaseCutoffFreqLow",2, ...
    "windowWidth", 0.3, ...
    "resultCutoffFreqLow",0.5);
pshe.process(slowTimePhase);
figure(111); pshe.plotHeartbeatSignal;
figure(121); pshe.plotStft;

%% BandPassHeartbeatExtractor
bphe = BandPassHeartbeatExtractor("PassBand",[0.8 1.8]);
bphe.process(slowTimePhase)
figure(991); bphe.plotResult()

% %% predict before combination
% predictables = {bphe, pshe};
% cellfun(@(x) x.predict("ErosePartLeft",0.1,"ErosePartRight",0.2,"PartConsidered",0.4),predictables)
% cellfun(@(x) x.setTfAnalysisOutput("predicted"),predictables)

%% Combined BandPassHeartbeatExtractor and PhaseStftHearbeatExtractor

rc = ResultsCombiner();
% rc.combine(bphe, pshe,"timeDelay2",0.15, "weights",[-1, 1]);
rc.combine(bphe, pshe,"estimateDelay",1,"estimateSign",0, ...
    "weights",[1, 1],"windowWidth",4,"windowStep",2,"maxAllowableShift",0.4);

figure(191); rc.plotEstimatedDelay()
figure(192); rc.plotResult()

%% prediction in breaks
predictables = {bphe, pshe,rc};
figure_nrs = [115,995,195];
for k = 1:length(predictables)
    predictables{k}.predict("ErosePartLeft",0,"ErosePartRight",0.15,"PartConsidered",0.4);
    figure(figure_nrs(k)); predictables{k}.plotPredictionResult()
    predictables{k}.setTfAnalysisOutput("predicted"); % "nonpredicted" / "predicted" 
end

% %% envelope normalization
% normWindow = 2; % seconds
% windowWidth = round(normWindow*rc.getSamplingFrequency);
% combinedSignalEnvelopeNorm = normalizeEnvelope(rc.combinedSignal,windowWidth);
% rc.combinedSignal = combinedSignalEnvelopeNorm;

% %% Inter-beat interval estimation
% [start_samples,end_samples] =  rc.getSegmentsStartsEnds;
% ibi = estimateIbi(combinedSignalEnvelopeNorm, rc.getSamplingFrequency, ...
%     "StartSamples",start_samples, ...
%     "EndSamples",end_samples, ...
%     "EroseSize",0);

%% Time-Frequency Analysis
tfAnalyzables = {pshe,bphe, rc};
tfaVect = {};
fig_nr = [1211 992 193];

for k = 1:length(tfAnalyzables)
    tfaVect{k} = TimeFreqAnalyzer( ...
        "WindowWidth",10, ...
        "FrequencyResolution",0.5/60, ...
        "MaximumVisibleFrequency",150/60, ...
        "Synchrosqueezed",1);
    tfaVect{k}.transform(tfAnalyzables{k})
    % find time-frequency ridge with memory
    tfaVect{k}.detectRidge( ...
    "NuberOfRidges",3, ...
    "PossibleLowFrequency",40/60,...
    "PossibleHighFrequency",150/60,...
    "JumpPenalty",1, ...
    "SelectMethod","first", ... "lowest" / "first" / "nearest" / "middle"
    "DesiredNearestFrequency", 80/60 ...
    );
    % find time-frequency ridge without memory
    frequencyDistanceToHarmonics = 1/mean(diff(slowTimeSignal.signalInfo.frameStartTimes)); % frame-length dependent
    tfaVect{k}.detectPeaks( ...
        "Method", "middle", ...  "highest" / "lower" / "middle" / "distanceBased"
        "ExactDistance",frequencyDistanceToHarmonics, ...
        "DistanceTolerance",0.3 * frequencyDistanceToHarmonics ...
        );
    figure(fig_nr(k));
    tfaVect{k}.plotResults( ...
        "QuantileVal",0.4,"AllRidges",1, "PlotRidges",1,"PlotPeaks",1,"PlotPeaksHarmonics",1)
end

%% Comparison with Reference: RMSE with Memory ------- 
% referencePath = "C:\Users\bfalecki\Documents\challenge\reference\kalenji\2025-12-04.fit";
referencePath = "/home/user/Documents/praca_mgr/measurements/reference/2025-12-04.fit";
hre = HeartRateReference(referencePath,"ManualTimeShift",1-5/3600);
cellfun(@(x) x.setHeartRateOutput("ridge"),tfaVect)
errors_memory = hre.calucateError(tfaVect);
figure(10101);hre.plot("otherResults",tfaVect, "showAdjusted",1)
disp("RMSE with memory in BPM: " + join(string(errors_memory)))

% Comparison with Reference: RMSE without Memory - - -  -
cellfun(@(x) x.setHeartRateOutput("peaks"),tfaVect)
errors_nomemory =  hre.calucateError(tfaVect);
figure(10102);hre.plot("otherResults",tfaVect)
disp("RMSE without memory in BPM: " + join(string(errors_nomemory)))

experiment = createExperimentStruct( ...
    errors_memory,errors_nomemory, ...
    tfaVect,loadConfig,preprocConfig, ...
    pshe,bphe,rc,hre);

table(errors_memory', errors_nomemory', ...
      'RowNames', experiment.errors.methods)

%% Save Parameters and Estimation Errors
% outDir = "results" + filesep + "phaser-process-exp" + filesep;
outDir = "/home/user/Documents/praca_mgr/processing/results/phaser-process-exp/";

% suffix
token = regexp(loadConfig.filename, '_vs([0-9.]+m)', 'tokens');
distLog = token{1}{1};
predictionApplied = strcmp(rc.furtherAnalysisOutput, "predicted");
synchrosqueezingApplied = tfaVect{3}.Synchrosqueezed == 1;
ridgeMethod = tfaVect{3}.detectRidgeSelectMethod;
peaksMethod = tfaVect{3}.detectPeaksMethod;
suffix = sprintf("dist%s_synchr%d_pred%d_ridge-%s_peaks-%s", ...
    distLog,synchrosqueezingApplied,predictionApplied,ridgeMethod,peaksMethod);

% prefix
baseName = "rec_04-Dec-2025";
custom_suffix = "";
suffix = suffix + custom_suffix;
save2file = 0;
if(save2file)
    outPathJson = makeOutputFilename(baseName, suffix, outDir,"extension",".json");
    saveJson(outPathJson, experiment);
end