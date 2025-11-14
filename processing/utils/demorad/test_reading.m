% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\test_gui\";
% filename = "test1.bin";
folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\vs\";
filename = "0.5.bin";

config_name = filename + ".conf";

filePath = folder + filename;
configPath = folder + config_name;

data = read_demorad(filePath);
cfg = readConfigDemorad(configPath);
data = drGetMatrix(data, cfg);
[RT,range_ax, t_ax] = drGetRT(data,cfg);
figure(2)
plot_surf(RT, t_ax,range_ax)
range_cell = 0.42; % meters
[slow_time] = drGetSlowTime(RT,range_cell, range_ax);
[sp,f_ax,t_ax] = stft_general(slow_time, cfg.PRF, WindowWidth=0.3, DesiredTimeRes=0.01, FrequencyResolution=1);
figure(1)
plot_surf(sp, t_ax, f_ax)


% slow time phase
[phase] = extractPhase(slow_time);
fdoppler = phase2fdoppler(phase,cfg.PRF);
vel = fdoppler2vel(fdoppler, cfg.Carrier);
[vel,actual_fs] = set_fs(vel, cfg.PRF, 100);

figure(3)
plot(vel)

PRF = actual_fs;
signal = vel;
