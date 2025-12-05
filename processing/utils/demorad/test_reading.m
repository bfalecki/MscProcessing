% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\pomiary2811\";
% filename = "vs10.bin";
% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\vs\";
% folder = "C:\Users\bfalecki\Documents\XY-DemoRad\Recordings\";
% filename = "vital-signs2.bin";
% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\test-interferences\";
% filename = "vs53.bin";
% folder = "C:\Users\bfalecki\Documents\praca_inz\matlab\old_measures_and_simulations\vital_signs\";
% filename = "breath3.bin";
folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\pomiary0412\";
filename = "vitsin2m.bin";

config_name = filename + ".conf";

filePath = folder + filename;
configPath = folder + config_name;

% data = read_demorad(filePath, "SkipSamples",1e6*60, "Samples",1e6*10);
data = read_demorad(filePath);
cfg = readConfigDemorad(configPath);
data = drGetMatrix(data, cfg);
% data = conj(data);
% data = data ./ mean(data, 2);

%%
figure(21)
data2plt = abs(data);
plot_surf(data2plt,"","",0,"","gray", [min(data2plt,[],"all") max(data2plt,[],"all")])
figure(22)
phase2plt = unwrap(angle(data).').';
% plot_surf(phase2plt,"","",0,"","gray", [min(phase2plt,[],"all") max(phase2plt,[],"all")])
plot_surf(phase2plt,"","",0,"","gray")
figure(23)
plot(real(data(:,1:500)),'b')
hold on
plot(imag(data(:,1:500)),'r')
hold off
%%
[RT,range_ax, t_ax] = drGetRT(data,cfg, ...
    "fast_time_data_start",50, "fast_time_data_end",[],"Window",'hann');
% RT_part = mti(RT(:,1:end).').';
% RT_part = RT(:,1000*60+(1:10000));
% RT_part = RT;
% RT_part = highpass(RT.',0.001, "ImpulseResponse","iir").';
figure(2)
plot_surf(RT_part, t_ax,range_ax)
% ylim([0 10])
range_cell_width = mean(diff(range_ax));

% figure(32)
% phaseRT2plt = unwrap(angle(RT_part).').';
% plot_surf(phaseRT2plt ,"","",0,"","gray")
% range_cell_of_choice = (13-1)*range_cell_width; % meters
%%
range_cell_of_choice =1.93;

[slow_time, range_cell_no] = drGetSlowTime(RT,range_cell_of_choice, range_ax);

%%
% slow_time_raw = slow_time(1:5000);
% [slow_time_compDC_mean, middle_mean] = compensateDc(slow_time_raw, "method",'mean');
% [slow_time_compDC_minstd,middle_minstd] = compensateDc(slow_time_raw, "method",'minstd');
% figure(12)
% plot(slow_time_raw, 'k')
% hold on
% plot(slow_time_compDC_mean, 'b')
% plot(slow_time_compDC_minstd, 'r')
% plot(0, 0, '*k')
% plot(-middle_mean, '*b')
% plot(-middle_minstd, '*r')
% hold off
% legend('not comp.','mean comp','minstd comp')





figure(31)
plotZ(t_ax, slow_time)

% slow_time = compensateDc(slow_time,"method",'minstd');


phase = extractPhase(slow_time,'atan');
unwrapped_phase_diff = compl_diff(diff(phase));
filtered_phase_diff = filter_noise_peaks(unwrapped_phase_diff, "Display",0,"ThresholdQuantile",0.9,"ThresholdMultiplier",3);
% slow_time_filt = filter_phase_jumps(slow_time, unwrapped_phase_diff,filtered_phase_diff);
slow_time_filt = slow_time;
win_width = 0.4;
oversampling = 5;
[sp,f_ax,t_ax_sp] = stft_general(slow_time_filt, cfg.PRF, ...
    WindowWidth=win_width, DesiredTimeRes=win_width/oversampling, FrequencyResolution=1/win_width/oversampling);
figure(1)
plot_surf(sp, t_ax_sp, fdoppler2vel(f_ax,cfg.Carrier),1, "", "jet")
ylim([-0.2 0.2])
ylabel('Radial Velocity [m/s]')

%%
fpass = 30; % Hz
% slow time phase
% figure(41)
phase = extractPhase(slow_time,'mdacm');
% plot(lowpass(diff(phase), fpass / cfg.PRF /2))
% hold on
% phase = extractPhase(slow_time,'dacm');
% plot(lowpass(diff(phase), fpass / actual_fs /2))
% phase = extractPhase(slow_time,'mdacm');
% plot(lowpass(diff(phase), fpass / actual_fs /2))
% legend("atan", 'dacm', 'mdacm')
% hold off

displacement = phase2displ(phase, cfg.Carrier);
fdoppler = phase2fdoppler(phase,cfg.PRF);
vel = fdoppler2vel(fdoppler, cfg.Carrier);

vel = filter_noise_peaks(vel, "Display",0,"ThresholdQuantile",0.9,"ThresholdMultiplier",3);

[vel_lp,actual_fs, t_ax_down] = set_fs(vel,cfg.PRF, 160);
vel_lp = lowpass(vel_lp, fpass*2 / actual_fs);

% [vel,actual_fs, t_ax_down] = set_fs(vel, cfg.PRF, 100);

figure(3)
plot(t_ax, vel)
hold on
plot(t_ax_down, vel_lp, "k")
hold off
ylabel("Velocity [m/s]")
% 
figure(4)
plot(t_ax, displacement*1e3)
ylabel("Displacement [mm]")

figure(5)
vel_fft = fft(vel_lp);
freq_ax = linspace(0, actual_fs, numel(vel_lp));
plot(freq_ax,abs(vel_fft),'b');
xlabel("f [Hz]")
ylabel("Amplitude")
xlim([0 80])

% PRF = cfg.PRF;
PRF = cfg.PRF;
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

% %% fsst
% [sp_fsst,f_ax_fsst,t_ax_fsst] = synchrosqueezing_general(vel,cfg.PRF, "FrequencyResolution",0.01, "MaximumVisibleFrequency",3,WindowWidth=5);
% figure(1)
% plot_surf(abs(sp_fsst), t_ax_fsst, 60*f_ax_fsst,0, "", 'gray')
% ylabel('Freq [BPM]')




% %% test Range-Time inversion
% % in theory: we can get the noise std of sqrt(1/(1+1/(std_ratio^2))) of the original
% % which is... 2% less only
% RT_original = RT;
% 
% RT_down = RT(2:ceil(end/2) , :);
% RT_up = flip(RT(ceil(end/2)+1:end, :));
% 
% std_ratio = 5; % std
% 
% RT_fused = RT_down + RT_up/(std_ratio^2); % Attention: not phase-synchronized
% 
% figure(40)
% plot_surf(abs(RT_down))
% 
% figure(41)
% plot_surf(abs(RT_up))
% 
% figure(42)
% plot_surf(abs(RT_fused))
% 
% RT = RT_fused;
% 
% 
