classdef PhaseStftHearbeatExtractor < handle & TimeFrequencyAnalyzable
    %PHASESTFTHEARBEATEXTRACTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        desiredTimeRes % [s], desired time resolution of the Short Time Fourier Transform (STFT)
        windowWidth % [s], window width of the STFT
        frequencyResolution % [Hz], Frequency Resolution of the STFT
        maximumVisibleFrequency % [Hz], Maximum Visible Frequency of the STFT
        heartOscillationFreqRange % [Hz] - fast oscillations of heartbeat 2-element vector, for lower and upper bound for accumulation
        phaseCutoffFreqLow % [Hz], cutoff low frequency before STFT computation
        resultCutoffFreqLow % [Hz], cutoff low frequency after signal extraction from STFT
            % usually we do not expect heart rate below 0.5 Hz, so better to get rid of it

        slowTimePhase % instance of SlowTimePhase or subclasses, the analyzed signal object

        % results after process()
        heartbeatSignal % time domain signal representing high-frequency heartbeat activity
        heartbeatSignalBreaks % heartbeatSignal without prediction (only in case of phaser)
        t_ax % [s] time axis of stft
        f_ax % [Hz] frequency axis of stft
        sp % stft IQ samples
        fs_stft % sampling frequency of the stft (along time axis)
    end
    
    methods
        function obj = PhaseStftHearbeatExtractor(opts)
            %PHASESTFTHEARBEATEXTRACTOR Construct an instance of this class
            %   set parameters
            arguments
                opts.desiredTimeRes = 1/40
                opts.windowWidth = 0.2
                opts.frequencyResolution = 1
                opts.maximumVisibleFrequency = 40
                opts.heartOscillationFreqRange = [10 20]
                opts.phaseCutoffFreqLow = 5
                opts.resultCutoffFreqLow = 0.5
            end
            obj.desiredTimeRes = opts.desiredTimeRes ;
            obj.windowWidth = opts.windowWidth ;
            obj.frequencyResolution = opts.frequencyResolution ;
            obj.maximumVisibleFrequency = opts.maximumVisibleFrequency ;
            obj.heartOscillationFreqRange = opts.heartOscillationFreqRange ;
            obj.phaseCutoffFreqLow = opts.phaseCutoffFreqLow ;
            obj.resultCutoffFreqLow = opts.resultCutoffFreqLow ;
        end

        function plotStft(obj)
            % plot STFT
            % only after process()
            max_val = max(db(obj.sp),[], "all");
            clim_min = quantile(db(nonzeros(obj.sp)),0.1,"all");
            clim_max = quantile(db(nonzeros(obj.sp)),0.99,"all");
            clims = [clim_min clim_max] - max_val; % max_value is substracted
            % cmap = flip(gray);
            cmap = "jet";
            plot_surf(obj.sp,obj.t_ax,obj.f_ax, 1,"", cmap, clims)
            xlabel("Time [s]"); ylabel("Frequency [Hz]");
            ylim([0 obj.maximumVisibleFrequency])
            c = colorbar;
            c.Label.String = 'Energy [dB]';
            title("Heartbeat Activity STFT")
        end

        function plotHeartbeatSignal(obj)
            % plot heartbeat detection signal
            % only after process()
            if(strcmp(obj.slowTimePhase.signalInfo.device, "phaser"))
                % differentiate between actual data and prediction
                plot(obj.t_ax,obj.heartbeatSignal, "LineWidth",1, "Color","b");
                hold on
                plot(obj.t_ax,obj.heartbeatSignalBreaks, "LineWidth",1.5, "Color","r");
                hold off
                legend("Predicted","Available")
            else
                plot(obj.t_ax,obj.heartbeatSignal, "LineWidth",1.5, "Color","k");
            end
            xlabel("Time [s]"); ylabel("Amplitude")
            title("Heartbeat Activity Signal")
            xlim([min(obj.t_ax) max(obj.t_ax)])
        end
        
        function process(obj,slowTimePhase)
            % process the data
            % input: slowTimePhase (instance of SlowTimePhase)

            % save it for informative purposes
            obj.slowTimePhase = slowTimePhase;

            signal = slowTimePhase.phase; % or filtered before

            % % we need to set proper fs
            % desired_fs = 100;
            % [signal,actual_fs, t_resampled]= set_fs(signal, PRF,desired_fs);
            
            % % we need then high-pass filter to cancel clutter and breath movement in spectrogram
            signal = highpass(signal, obj.phaseCutoffFreqLow / (slowTimePhase.signalInfo.PRF/2));
            
            
            % STFT calculation
            
            [obj.sp,obj.f_ax,obj.t_ax,obj.fs_stft,overlap_len] = stft_general( ...
                signal,slowTimePhase.signalInfo.PRF,...
                "DesiredTimeRes",obj.desiredTimeRes, ...
                "FrequencyResolution",obj.frequencyResolution,...
                "WindowWidth",obj.windowWidth, ...
                "MaximumVisibleFrequency", obj.maximumVisibleFrequency);
            
            % sp = sp ./ sum(abs(sp),2);
            % extract heart cycles signal
            heart_cycles_detected = extract_env_sp(obj.sp,obj.f_ax, ...
                "FreqRange",obj.heartOscillationFreqRange, ...
                "LogScale",0);

            obj.heartbeatSignal = highpass(heart_cycles_detected, ...
                obj.resultCutoffFreqLow / (obj.fs_stft/2));

            % if phaser, we do the autoregressive prediction
            if(strcmp(slowTimePhase.signalInfo.device, "phaser"))
                % we need to determine segments start/end idxes on stft
                [start_samples_stft,end_samples_stft] = convert_segments_sp(...
                    slowTimePhase.segmentStartIndices, ...
                    slowTimePhase.segmentEndIndices, ...
                    slowTimePhase.signalInfo.PRF, obj.fs_stft, overlap_len);
                % also binary idxes are necessary
                segments_idxes_stft = get_segments_idxes(start_samples_stft,end_samples_stft, length(obj.heartbeatSignal));

                % save signal with breaks
                obj.heartbeatSignalBreaks = obj.heartbeatSignal;
                obj.heartbeatSignalBreaks(~segments_idxes_stft) = nan;

                % now we must perform signal prediction in breaks
                obj.heartbeatSignal = fill_gaps_ar_wrapped(obj.heartbeatSignal,...
                    obj.fs_stft, segments_idxes_stft,slowTimePhase.segmentDuration,"PartConsidered",1);
                
                % also, we can zero-out sp in breaks
                obj.sp(:,~segments_idxes_stft) = 0;
            end

        end


        % Abstract methods implementations for TimeFrequencyAnalyzable
        function startDateTime = getStartDateTime(obj)
            startDateTime = obj.slowTimePhase.signalInfo.timeStart;
        end
        function samplingFrequency = getSamplingFrequency(obj)
            samplingFrequency = obj.fs_stft;
        end
        function signal = getSignal(obj)
            signal = obj.heartbeatSignal;
        end

    end
end

