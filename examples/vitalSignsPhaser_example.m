% configDir = "/home/user/Documents/praca_mgr/processing/results/phaser-process-exp/";
configDir = "C:\Users\bfalecki\Documents\praca_mgr\processing\results\phaser-process-exp\";
configFilename = "rec_04-Dec-2025__dist0.5m_synchr0_pred1_ridge-first_peaks-highest_best.json";
% configFilename = "rec_04-Dec-2025__dist2m_synchr0_pred1_ridge-first_peaks-highest_best.json";
% configFilename = "rec_04-Dec-2025__dist1m_synchr0_pred1_ridge-first_peaks-highest_best.json";

experiment = readJson(configDir + configFilename);

folder = "C:\Users\bfalecki\Documents\challenge\rec\";
% folder = "/home/user/Documents/praca_mgr/measurements/phaser/";

filename = experiment.loading.filename;
range_cell = experiment.preprocessing.range_cell; % meters

rangeCellMeters = [0.25 2.5];

lengthSeconds = experiment.loading.lengthSeconds;
offsetSeconds = experiment.loading.offsetSeconds;
rawData = readRawPhaser(folder+filename,"lengthSeconds",lengthSeconds,"offsetSeconds",offsetSeconds);
loadConfig = SignalLoadingConfig(lengthSeconds,offsetSeconds,filename);

%%
% figure(1); rawData.plotIQ()
% figure(2); rawData.plotMatrix()

%% 

fast_time_data_start = experiment.preprocessing.fast_time_data_start;
fast_time_data_end = experiment.preprocessing.fast_time_data_end;
FastTimeWindow = experiment.preprocessing.FastTimeWindow;
rangeTimeMap = raw2rtm(rawData, ...
    "fast_time_data_start",fast_time_data_start, ...
    "fast_time_data_end",fast_time_data_end, ...
    "Window",FastTimeWindow);
slowTimeSignal = rtm2sts(rangeTimeMap,rangeCellMeters);
slowTimeSignal.selectSingleCell(range_cell);
phaseUnwrappingMethod = experiment.preprocessing.phaseUnwrappingMethod; % not used, it is always 'atan' after removePhaseDiscontinuities

%% preprocessing
figure(6); [slowTimePhase, phaseDiscontCompParams] = ...
    slowTimeSignal.removePhaseDiscontinuities( ...
    "Display",1, ...
    "ThresholdQuantile",experiment.preprocessing.phaseDiscontCompParams.ThresholdQuantile, ...
    "ThresholdMultiplier",experiment.preprocessing.phaseDiscontCompParams.ThresholdMultiplier, ...
    "NeighborSize",experiment.preprocessing.phaseDiscontCompParams.NeighborSize, ...
    "SegmentsBounds",experiment.preprocessing.phaseDiscontCompParams.SegmentsBounds);
preprocConfig = PreprocessingConfig(range_cell,fast_time_data_start,fast_time_data_end,FastTimeWindow,phaseUnwrappingMethod,phaseDiscontCompParams);

slowTimePhase.removeLinearPhase()

figure(3); slowTimeSignal.plotSignal()
figure(4); slowTimePhase.plotPhase()
figure(5); slowTimePhase.plotPhaseDiff()

% %% optional save pre-processed signal to file
% preprocDir = "data" + filesep;
% filepathPreprocessed = makeOutputFilename(filename, "preproc", preprocDir, "extension",".mat");
% save(filepathPreprocessed, "slowTimeSignal","slowTimePhase","loadConfig","preprocConfig")

% %% optional start: read pre-processed signal from file
% 
% configDir = "/home/user/Documents/praca_mgr/processing/results/phaser-process-exp/";
% configFilename = "trial-params.json";
% experiment = readJson(configDir + configFilename);
% 
% filepathPreprocessed = "data"+filesep+"phaser_rec_04-Dec-2025_18-23-11_vs0.5m__preproc.mat";
% % filepathPreprocessed = "data"+filesep+"phaser_rec_04-Dec-2025_18-39-31_vs1m__preproc.mat";
% % filepathPreprocessed = "data"+filesep+"phaser_rec_04-Dec-2025_18-46-23_vs2m__preproc.mat";
% 
% preprocFile = load(filepathPreprocessed);
% loadConfig = preprocFile.loadConfig;
% preprocConfig = preprocFile.preprocConfig;
% slowTimePhase =  preprocFile.slowTimePhase;
% slowTimeSignal =  preprocFile.slowTimeSignal;
% 

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
tfa0.detectPeaks("Method","highest")
figure(312); tfa0.plotResults("QuantileVal",0.8,"AllRidges",1,"PlotPeaks",1, "PlotRidges",1)

%% PhaseStftHearbeatExtractor
% configFilename = "trial-params.json";
% experiment = readJson(configDir + configFilename);

pshe = PhaseStftHearbeatExtractor( ...
    "heartOscillationFreqRange", experiment.pshe.heartOscillationFreqRange, ...
    "frequencyResolution",experiment.pshe.frequencyResolution, ...
    "phaseCutoffFreqLow",experiment.pshe.phaseCutoffFreqLow, ...
    "windowWidth", experiment.pshe.windowWidth, ...
    "resultCutoffFreqLow",experiment.pshe.resultCutoffFreqLow, ...
    "desiredTimeRes",experiment.pshe.desiredTimeRes, ...
    "maximumVisibleFrequency",experiment.pshe.maximumVisibleFrequency);
pshe.process(slowTimePhase);

figure(111); pshe.plotHeartbeatSignal;
figure(121); pshe.plotStft;

%% BandPassHeartbeatExtractor
bphe = BandPassHeartbeatExtractor( ...
    "PassBand",experiment.bphe.PassBand, ...
    "UpsamplingFactor",experiment.bphe.UpsamplingFactor);
bphe.process(slowTimePhase)
figure(991); bphe.plotResult()

%% Combined BandPassHeartbeatExtractor and PhaseStftHearbeatExtractor

rc = ResultsCombiner();
rc.combine(bphe, pshe, ...
    "estimateDelay",experiment.rc.input.estimateDelay, ...
    "estimateSign",experiment.rc.input.estimateSign, ...
    "weights",[experiment.rc.input.weight1, experiment.rc.input.weight2], ...
    "windowWidth",experiment.rc.adjustment.windowWidth, ...
    "windowStep",experiment.rc.adjustment.windowStep, ...
    "maxAllowableShift",experiment.rc.adjustment.maxAllowableShift, ...
    "timeDelay2",experiment.rc.input.timeDelay2);

figure(191); rc.plotEstimatedDelay()
figure(192); rc.plotResult()

%% prediction in breaks
% configFilename = "trial-params.json";
% experiment = readJson(configDir + configFilename);
predictables = {bphe, pshe,rc};
predictionParameters = {experiment.bphe.prediction, experiment.pshe.prediction,experiment.rc.prediction};
figure_nrs = [115,995,195];
for k = 1:length(predictables)
    predictables{k}.predict( ...
        "ErosePartLeft",predictionParameters{k}.ErosePartLeft, ...
        "ErosePartRight",predictionParameters{k}.ErosePartRight, ...
        "PartConsidered",predictionParameters{k}.PartConsidered);
    figure(figure_nrs(k)); predictables{k}.plotPredictionResult()
    predictables{k}.setTfAnalysisOutput(predictionParameters{k}.furtherAnalysisOutput); % "nonpredicted" / "predicted" 
end

%% Time-Frequency Analysis
tfAnalyzables = {pshe,bphe, rc};
tfaVect = {};
fig_nr = [1211 992 193];

for k = 1:length(tfAnalyzables)
    tfaVect{k} = TimeFreqAnalyzer( ...
        "WindowWidth",experiment.tfa(k).WindowWidth, ...
        "FrequencyResolution",experiment.tfa(k).FrequencyResolution, ...
        "MaximumVisibleFrequency",experiment.tfa(k).MaximumVisibleFrequency, ...
        "Synchrosqueezed",experiment.tfa(k).Synchrosqueezed);
    tfaVect{k}.transform(tfAnalyzables{k})
    % find time-frequency ridge with memory
    tfaVect{k}.detectRidge( ...
    "NuberOfRidges",experiment.tfa(k).detectRidgeNuberOfRidges, ...
    "PossibleLowFrequency",experiment.tfa(k).detectRidgePossibleLowFrequency,...
    "PossibleHighFrequency",experiment.tfa(k).detectRidgePossibleHighFrequency,...
    "JumpPenalty",experiment.tfa(k).detectRidgeJumpPenalty, ...
    "SelectMethod",experiment.tfa(k).detectRidgeSelectMethod, ... "lowest" / "first" / "nearest" / "middle"
    "DesiredNearestFrequency", experiment.tfa(k).detectRidgeDesiredNearestFrequency ...
    );
    % find time-frequency ridge without memory
    frequencyDistanceToHarmonics = 1/mean(diff(slowTimeSignal.signalInfo.frameStartTimes)); % frame-length dependent
    tfaVect{k}.detectPeaks( ...
        "Method", experiment.tfa(k).detectPeaksMethod, ...  "highest" / "lower" / "middle" / "distanceBased"
        "ExactDistance",experiment.tfa(k).detectPeaksExactDistance, ...
        "DistanceTolerance",experiment.tfa(k).detectPeaksDistanceTolerance ...
        );
    figure(fig_nr(k));
    tfaVect{k}.plotResults( ...
        "QuantileVal",0.4,"AllRidges",0, "PlotRidges",1,"PlotPeaks",1,"PlotPeaksHarmonics",0)
end

%% Comparison with Reference: RMSE with Memory ------- 
referencePath = "C:\Users\bfalecki\Documents\challenge\reference\kalenji\2025-12-04.fit";
% referencePath = "/home/user/Documents/praca_mgr/measurements/reference/2025-12-04.fit";
hre = HeartRateReference(referencePath,"ManualTimeShift",hours(duration(experiment.hre.ManualTimeShift)));
cellfun(@(x) x.setHeartRateOutput("ridge"),tfaVect)
errors_memory = hre.calucateError(tfaVect);
figure(10101);hre.plot("otherResults",tfaVect(2:3), "showAdjusted",1)
disp("RMSE with memory in BPM: " + join(string(errors_memory)))

% Comparison with Reference: RMSE without Memory - - -  -
cellfun(@(x) x.setHeartRateOutput("peaks"),tfaVect)
errors_nomemory =  hre.calucateError(tfaVect);
figure(10102);hre.plot("otherResults",tfaVect(2:3))
disp("RMSE without memory in BPM: " + join(string(errors_nomemory)))


table(errors_memory', errors_nomemory', ...
      'RowNames', ["pshe","bphe","rc"])

%% Save Parameters and Estimation Errors
% outDir = "results" + filesep + "phaser-process-exp" + filesep;
% outDir = "/home/user/Documents/praca_mgr/processing/results/phaser-process-exp/";
outDir = configDir;

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
custom_suffix = "_best";
suffix = suffix + custom_suffix;

save2file = 1;
if(save2file)

    experiment = createExperimentStruct( ...
        errors_memory,errors_nomemory, ...
        tfaVect,loadConfig,preprocConfig, ...
        pshe,bphe,rc,hre);

    outPathJson = makeOutputFilename(baseName, suffix, outDir,"extension",".json");
    saveJson(outPathJson, experiment);
end