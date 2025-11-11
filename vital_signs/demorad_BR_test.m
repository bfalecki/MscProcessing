% This script make the test of demorad recording if it it possible to
% extract breath from the phase using the approach from
% radarconf'25 challenge

% see demorad_HR_test.m for input file generation

% parse inputs
folder = "/home/user/Documents/praca_inz/matlab/old_measures_and_simulations/extracted/";
% filename = "heartBeat_phase_diff.mat";
filename = "breath_phase_diff.mat";
file = load(folder + filename);
signal = file.velocity_MDACM;
PRF = file.PRF;

% we need to set proper fs
desired_fs = 100;
[signal,actual_fs, timeLags]= set_fs(signal, PRF,desired_fs);

displacement = vel2displ(signal,actual_fs);
% offset cancellation
displacement = displacement - mean(displacement);

cutoff_freq_low = 0.05; % we do not expect breath rate below 0.05 Hz
displacement = highpass(displacement, cutoff_freq_low/actual_fs);

%% instantaneous respiratory rate using synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(displacement,actual_fs,...
    "FrequencyResolution",1/60/4,"MaximumVisibleFrequency",1.5, "WindowWidth",10);

% then find tfridge
f_low_breath_expected = 0.05; % minimum breath rate expected
f_high_breath_expexcted = 1; % maximum breath rate expected
[ridge, synchrosqueezed, f_ax_fsst] = find_tfridge(synchrosqueezed, f_ax_fsst,...
    "JumpPenalty",0.02, "NuberOfRidges",1,...
    "PossibleHighFrequency",f_high_breath_expexcted,...
    "PossibleLowFrequency",f_low_breath_expected);

% plot Result
f_ax_bpm = f_ax_fsst*60;
ridge_bpm = ridge*60;


% --- wrap into structs ---

% 1. Differentiated Phase
results.phase.time = timeLags;
results.phase.data = compl_diff(diff(displacement));

% 2. Displacement
results.displacement.time = timeLags;
results.displacement.data1 = displacement * 1e3;
results.displacement.data2 = [];

% 3. Synchrosqueezed STFT
results.sstft.t = t_ax_fsst;
results.sstft.f = f_ax_bpm;
results.sstft.spectrogram = synchrosqueezed;
results.sstft.ridge = ridge_bpm;
results.sstft.cdata_sstft = prep_cdata(synchrosqueezed, "QuantileVal",0.5);


handles = initBreathPlots();
plotBreathResults(results,handles);