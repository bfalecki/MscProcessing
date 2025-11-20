% This script make the test of demorad recording if it it possible to
% extract heartbeat from the differentiated phase using the approach from
% radarconf'25 challenge (STFT extraction)


% inputs: 
% signal = differentatied phase signal (can be velocity)
% PRF (Hz)
% How to prepare file:
%   1. Go to praca_inz/matlab/old_measures_and_simulations/         (in MATLAB)
%   2. Add 'scripts' to path
%   3. Open any config, for example 'breath.m'
%   4. Set constant and single range cell, disable any clutter filtering
%   5. Run the script
%   6. Open signal_analysis.m
%   7. Run extract_matrix, range-time, extract_slow_time_signal, and phase_demodulation
%   8. save("extracted"+filesep+"{recname}_phase_diff.mat", "PRF", "velocity_MDACM", "time_base_phase")

% % parse inputs
% folder = "/home/user/Documents/praca_inz/matlab/old_measures_and_simulations/extracted/";
% % filename = "heartBeat_phase_diff.mat";
% filename = "breath_phase_diff.mat";
% file = load(folder + filename);
% signal = file.velocity_MDACM;
% PRF = file.PRF;

% measured signal needs to be filtered regarding outstanding peaks...
figure(1)
signal_filt = filter_noise_peaks(signal, ...
    "Display", 1, ...
    'ThresholdQuantile', 0.9, ...
    'ThresholdMultiplier',3);
% signal_filt = signal;

% we need to set proper fs
desired_fs = 100;
[signal_filt,actual_fs, t_resampled]= set_fs(signal_filt, PRF,desired_fs);

% % we need then high-pass filter to cancel clutter and breath movement in spectrogram
% phase_cutoff_freq_low = 5; % Hz
phase_cutoff_freq_low = 2;
signal_filt = highpass(signal_filt, phase_cutoff_freq_low / (actual_fs/2));


%% STFT calculation

[sp,f_ax,t_ax,fs_stft,overlap_len] = stft_general(signal_filt,actual_fs,...
    "DesiredTimeRes",1/40, "FrequencyResolution",1,...
    "WindowWidth",0.25, "MaximumVisibleFrequency",40);

% sp = sp ./ sum(abs(sp),2);
% extract heart cycles signal
heart_oscillation_freq_range = [0 30]; % Hz - fast oscillations of heartbeat
heart_cycles_detected = extract_env_sp(sp,f_ax,"FreqRange",heart_oscillation_freq_range, "LogScale",0, "Normalize",0);
% we do not expect heart rate below 0.5 Hz, so better to get rid of i
cutoff_freq_low = 0.5;
heart_cycles_detected = highpass(heart_cycles_detected,cutoff_freq_low / (fs_stft/2));


%% synchrosqueezing
[synchrosqueezed,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(heart_cycles_detected,fs_stft,...
    "FrequencyResolution",1/60,"MaximumVisibleFrequency",3, "WindowWidth",5);

% then find tfridge
f_low_hb_expected = 0.6; % minimum heart rate expected
f_high_hb_expexcted = 3; % maximum heart rate expected
[ridge, synchrosqueezed, f_ax_fsst] = find_tfridge(synchrosqueezed, f_ax_fsst,...
    "JumpPenalty",1, "NuberOfRidges",1,...
    "PossibleHighFrequency",f_high_hb_expexcted,...
    "PossibleLowFrequency",f_low_hb_expected);

% plot Result
f_ax_bpm = f_ax_fsst*60;
ridge_bpm = ridge*60;


% 1. Filtered Phase Differentiation
results.filteredPhase.time = t_resampled(1:length(signal_filt));
results.filteredPhase.data = signal_filt / actual_fs;

% 2. STFT
results.stft.spectrogram = sp;
results.stft.t = t_ax;
results.stft.f = f_ax;
results.stft.cdata_stft = prep_cdata(sp, "QuantileVal",0.2);

% 3. Extracted signal from STFT
results.extractedSignal.t = t_ax;
results.extractedSignal.predicted = [];
results.extractedSignal.available = heart_cycles_detected;

% 4. Synchrosqueezed STFT
results.sstft.t = t_ax_fsst;
results.sstft.f = f_ax_bpm;
results.sstft.spectrogram = synchrosqueezed;
results.sstft.ridge = ridge_bpm;
results.sstft.cdata_sstft = prep_cdata(synchrosqueezed, "QuantileVal",0.2);

%% Plot
handles = initHeartbeatPlots();
plotHeartbeatResults(results,handles);


%% compare with reference

compare_with_reference = 1;
if(compare_with_reference)
    % load reference measurement (from decathloncoach)
    % ref_path = "reference\kalenji\eu2dfde107c18a00b528_2025-10-02_fitness.fit";
    ref_folder = "C:\Users\bfalecki\Documents\challenge\reference\kalenji\";
    % ref_path = ref_folder + "eu2231dc9cce5eb99169_2025-11-18_fitness.fit"; % phaser_rec_18-Nov-2025_15-01-06_vital-signs1.mat
    % ref_path = ref_folder + "eu2c4ef44ec1b408eb74_2025-11-18_fitness.fit"; % demorad24
    % ref_path = ref_folder + "2025-11-20_demorad180s-0.5m.fit";
    ref_path = ref_folder + "2025-11-20_demorad30s-1m.fit";
    [heart_rate_ref, time_ref] = parse_fit(ref_path);
    time_ref = time_ref + hours(1); % UTC fix - or hours(2)

    % adjust radar measurement
    radar_t_relative = results.sstft.t;
    radar_heart_rate = results.sstft.ridge;
    % get filename
    dt_start = datetime(cfg.StartedAt);
    radar_time = dt_start + seconds(radar_t_relative);

    figure(123)
    plot(radar_time, radar_heart_rate)
    hold on
    plot(time_ref, heart_rate_ref)
    hold off
    xlabel("Time")
    ylabel("Heart rate [BPM]")
    legend("Radar", "Kalenji Reference")
    grid on
    ylim([50 100])

end