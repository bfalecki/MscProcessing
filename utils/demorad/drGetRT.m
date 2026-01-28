function [RT,range_ax, t_ax] = drGetRT(data,cfg,opts)
%GETPHASEDIFF Summary of this function goes here
%   data - data matrix - pulses

    
    arguments
        data 
        cfg 
        opts.fast_time_data_start = 1
        opts.fast_time_data_end = cfg.SamplingFreq / cfg.PRF
        opts.Window = 'gauss' % gaussian window
        opts.GaussWidth = 0.5 % in case of Gaussian window
    end
    
    if(isempty(opts.fast_time_data_end))
        opts.fast_time_data_end = cfg.SamplingFreq / cfg.PRF;
    end
    if(isempty(opts.fast_time_data_start))
        opts.fast_time_data_start = 1;
    end
    if(isempty(opts.Window))
        opts.Window = 'no';
    end
    
    data = data(opts.fast_time_data_start:opts.fast_time_data_end, :);

    if(strcmp(opts.Window, 'gauss'))
        data = applyGaussWindow(data,opts.GaussWidth);
    elseif(strcmp(opts.Window, 'hann'))
        window = hann(size(data,1));
        data = data .* window;
    elseif(strcmp(opts.Window, 'hamming'))
        window = hamming(size(data,1));
        data = data .* window;
    elseif(strcmp(opts.Window, 'no'))
        
    end

    
    
    RT = fft(data);
    f_ax = linspace(0,cfg.SamplingFreq,size(RT,1)); % freq ax
    range_ax = physconst('LightSpeed')*f_ax/2/cfg.Bandwidth/cfg.PRF; % range ax
    t_max = (size(RT,2)-1) / cfg.PRF;
    t_ax = linspace(0, t_max ,size(RT,2));
end

