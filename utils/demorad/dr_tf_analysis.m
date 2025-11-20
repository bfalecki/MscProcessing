% folder = "C:\Users\bfalecki\Documents\praca_mgr\measurements\demorad\new\vs\";
% filename = "0.5.bin";
folder = "C:\Users\bfalecki\Documents\XY-DemoRad\Recordings\";
filename = "falls-behavior.bin";

config_name = filename + ".conf";

filePath = folder + filename;
configPath = folder + config_name;

data = read_demorad(filePath);
cfg = readConfigDemorad(configPath);
data = drGetMatrix(data, cfg);
%%
[RT,range_ax, t_ax] = drGetRT(data,cfg, "fast_time_data_start",50);
RT = mti(RT);
% RT = resample(RT, 1,4);
figure(2)
plot_surf(RT(:,1:50000), t_ax,range_ax)
ylim([0 5])
%%
range_cell_width = mean(diff(range_ax));
% range_cell_of_choice = (8-1)*range_cell_width; % meters
range_cell_of_choice = [1 2];

dt_start = datetime(cfg.StartedAt);

radar_signal = drGetSlowTime(RT, range_cell_of_choice,range_ax);
% radar_signal = compensateDc(radar_signal);
win_width = 0.05;
[sp,f_ax,t_ax] = stft_fused(radar_signal, cfg.PRF,...
    "WindowWidth",win_width, "FrequencyResolution",1/win_width/3, "DesiredTimeRes",win_width/3,...
    "thresholdDb",40);

%%
figure(4)
sp_norm = db(sp);
noise_lvl = quantile(sp_norm(sp_norm ~= -inf),0.0, "all");
sp_norm = sp_norm - noise_lvl;
plot_surf(sp_norm,dt_start + seconds(t_ax), fdoppler2vel(f_ax,cfg.Carrier), 0,"", 'jet')
clims = clim;
clim([0 max(sp_norm, [], "all")])
ylabel('Radial Velocity [m/s]')
hc = colorbar;
set(hc.Label, "String", 'Energy [dB]')