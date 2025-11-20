% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\test_gui\";
% filename = "test1.bin";
% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\vs\";
folder = "C:\Users\bfalecki\Documents\XY-DemoRad\Recordings\";
filename = "vital-signs4.bin";

config_name = filename + ".conf";

filePath = folder + filename;
configPath = folder + config_name;

data = read_demorad(filePath);
cfg = readConfigDemorad(configPath);
data = drGetMatrix(data, cfg);
%%
[RT,range_ax, t_ax] = drGetRT(data,cfg, "fast_time_data_start",40, "fast_time_data_end",200);
% RT_part = mti(RT(:,1:end));
% % RT_part = RT(:,1:10000);
% figure(2)
% plot_surf(RT_part, t_ax,range_ax)
% ylim([0 2])
range_cell_width = mean(diff(range_ax));
% range_cell_of_choice = (13-1)*range_cell_width; % meters
%%
range_cell_of_choice = 1;

[slow_time, range_cell_no] = drGetSlowTime(RT,range_cell_of_choice, range_ax);
[slow_time, actual_fs, t_ax_down] = set_fs(slow_time, cfg.PRF,100);
% % actual_fs = cfg.PRF; t_ax_down = t_ax;
% 
disp(range_cell_no)
slow_time = compensateDc(slow_time);
win_width = 0.3;
oversampling = 5;
[sp,f_ax,t_ax_sp] = stft_general(slow_time, actual_fs, ...
    WindowWidth=win_width, DesiredTimeRes=win_width/oversampling, FrequencyResolution=1/win_width/oversampling);
figure(1)
plot_surf(sp, t_ax_sp, fdoppler2vel(f_ax,cfg.Carrier),1, "", "jet")
ylim([-0.05 0.05])
ylabel('Radial Velocity [m/s]')


% slow time phase
phase = extractPhase(slow_time);
displacement = phase2displ(phase, cfg.Carrier);
fdoppler = phase2fdoppler(phase,actual_fs);
vel = fdoppler2vel(fdoppler, cfg.Carrier);
% figure(33)
% vel = filter_noise_peaks(vel, "Display",1,"ThresholdQuantile",0.9,"ThresholdMultiplier",3);
% [vel,actual_fs, t_ax_down] = set_fs(vel, cfg.PRF, 100);

figure(3)
plot(t_ax_down, vel*1e3)
ylabel("Velocity [mm/s]")
% 
figure(4)
plot(t_ax_down, displacement*1e3)
ylabel("Displacement [mm]")

% PRF = cfg.PRF;
PRF = actual_fs;
signal = vel;


% DWT
% [ca1,cd1] = dwt(signal, 'db4');
% [ca2,cd2] = dwt(ca1, 'db4');
% [ca3,cd3] = dwt(ca2, 'db4');
% %%
% figure(45)
% plot(cd2)
% 
% signal = cd2;
% PRF = actual_fs/4;

%% fsst
[sp_fsst,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(vel,actual_fs, "FrequencyResolution",0.01, "MaximumVisibleFrequency",3,WindowWidth=5);
figure(1)
plot_surf(abs(sp_fsst), t_ax_fsst, 60*f_ax_fsst,0, "", 'gray')
ylabel('Freq [BPM]')