function rangeTimeMap = raw2rtm(rawData, opts)
%DATA2RTM Processes raw data in a form of RawData instance to a RangeTimeMap
%object
    arguments
        rawData 
        opts.fast_time_data_start = 1
        opts.fast_time_data_end = size(rawData.data,1) % rawData.signalInfo.samplingFrequency / rawData.signalInfo.PRF
        opts.Window = 'gauss' % gaussian window
        opts.GaussWidth = 0.5 % in case of Gaussian window
    end

    if(isempty(opts.fast_time_data_end))
        opts.fast_time_data_end = size(rawData.data,1); % rawData.signalInfo.samplingFrequency / rawData.signalInfo.PRF;
    end
    if(isempty(opts.fast_time_data_start))
        opts.fast_time_data_start = 1;
    end
    if(isempty(opts.Window))
        opts.Window = 'no';
    end
    
    data = rawData.data(opts.fast_time_data_start:opts.fast_time_data_end, :);

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
    % rawData.signalInfo.samplingFrequency or
    % rawData.signalInfo.samplingFrequency/2   ????
    % device-dependent ?
    if(strcmp(rawData.signalInfo.device,"phaser"))
        f_ax = linspace(0,rawData.signalInfo.samplingFrequency/2,size(RT,1)); % freq ax
    else
        f_ax = linspace(0,rawData.signalInfo.samplingFrequency,size(RT,1)); % freq ax
    end
    
    range_ax = physconst('LightSpeed')*f_ax/2/  rawData.signalInfo.bandWidth  /   rawData.signalInfo.PRF; % range ax
    t_max = (size(RT,2)-1) / rawData.signalInfo.PRF;
    t_ax = linspace(0, t_max ,size(RT,2));

    if(strcmp(rawData.signalInfo.device,"phaser")) % cut some range cells from the beggining
        ncuts = 3;
        range_ax = range_ax(1:end-ncuts);
        RT = RT(ncuts+1:end,:);
    end

    rangeTimeMap = RangeTimeMap(RT,range_ax,t_ax,rawData.signalInfo);

end

