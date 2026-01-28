% parse inputs
folder = "/home/user/Documents/praca_inz/matlab/old_measures_and_simulations/extracted/";
% filename = "heartBeat_phase_diff.mat";
filename = "breath_phase_diff.mat";
file = load(folder + filename);
signal = file.velocity_MDACM;
PRF = file.PRF;

% measured signal needs to be filtered regarding outstanding peaks...
signal_filt = filter_noise_peaks(signal, ...
    "Display", 1, ...
    'ThresholdQuantile', 0.9, ...
    'ThresholdMultiplier',3);

% we need to set proper fs
desired_fs = 100;
[signal_filt,actual_fs, t_resampled]= set_fs(signal_filt, PRF,desired_fs);

% db wavelets:

[c,l] = wavedec(signal_filt, 4, 'db5');