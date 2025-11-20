function [sp_fused,f_ax,t_ax,fs_stft,overlap_len_original_fs] = stft_fused(RT_part,SamplingFrequency,opts)
%STFT_FUSED Summary of this function goes here
%   Detailed explanation goes here

    arguments
        RT_part % multiple slow-time signals
        SamplingFrequency % Sampling frequency of the signal [Hz]
        opts.MaximumVisibleFrequency = SamplingFrequency/2; % Maximum visible
                % frequency on the distribution [Hz]
        opts.FrequencyResolution = SamplingFrequency/200; % Desired frequency resoultion [Hz]
        opts.WindowWidth = 0.1*length(size(RT_part,2))/SamplingFrequency; % FWHM of the gaussian window function [s]
        opts.DesiredTimeRes = 1/SamplingFrequency % desired time cell size [s]
        opts.thresholdDb = 20 % reject samples below threshold
    end

    sp_fused = [];

    for k = 1:size(RT_part, 1)
        signal = RT_part(k,:);
        [sp,f_ax,t_ax,fs_stft,overlap_len_original_fs] = stft_general(signal,...
            SamplingFrequency,"DesiredTimeRes",opts.DesiredTimeRes,...
            "FrequencyResolution",opts.FrequencyResolution,"MaximumVisibleFrequency",opts.MaximumVisibleFrequency,...
            "WindowWidth",opts.WindowWidth);
        sp = abs(sp);
        % thresh = quantile(sp,opts.thresholdQuantile,"all");
        thresh_db = max(db(sp), [], "all") - opts.thresholdDb;
        thresh = 10^(thresh_db/20);
        sp(sp < thresh) = 0;
        if(isempty(sp_fused))
            sp_fused = sp;
        else
            sp_fused = sp_fused + sp;
        end
    end

    

end

