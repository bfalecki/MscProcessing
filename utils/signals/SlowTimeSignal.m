classdef SlowTimeSignal < SlowTimeSignalAny
    %SLOWTIMESIGNAL
    
    properties
        signal % complex double vector, IQ raw signal from range-time map
    end
    
    methods
        function obj = SlowTimeSignal()
            %SLOWTIMESIGNAL Construct an instance of this class
        end

        function initialize(obj, varargin)
            initialize@SlowTimeSignalAny(obj, varargin{:});
        end

        function setSignal(obj,signal)
            obj.signal = signal;
            
        end

        function selectSingleCell(obj, rangeCellMeters)
            % see documentation for selectSingleCell@SlowTimeSignalAny
            relativeIdx = selectSingleCell@SlowTimeSignalAny(obj,rangeCellMeters);
            obj.signal = obj.signal(relativeIdx, :);
            
        end

        function plotSignal(obj)
            % display phase signal
            t_ax = obj.getTimeAx();
            if(~isscalar(obj.actualRangeCellsMeters))
                plot(t_ax,real(obj.signal).', LineWidth=2);
                ax = gca;
                ax.ColorOrderIndex = 1;
                hold on
                plot(t_ax,imag(obj.signal).', LineWidth=1);
                hold off
                legend(string(obj.actualRangeCellsMeters) + " m")
            else
                plot(t_ax,real(obj.signal));
                hold on
                plot(t_ax,imag(obj.signal));
                hold off
                legend("Real Part", "Imag. Part")
            end
            xlabel("Time [s]")
            ylabel("Amplitude")
        end
        function t_ax = getTimeAx(obj)
            t_ax = 0: 1/obj.signalInfo.PRF : (size(obj.signal,2)-1) / obj.signalInfo.PRF;
        end

        function slowTimePhase_filt = removePhaseDiscontinuities(obj, opts)
            % remove phase discontinuities
            % TO DO: add filter_noise_peaks parameters

            % output:
            % slowTimePhase_filt - SlowTimePhase instance with filtering
            % applied (extracted using atan method)

            arguments
                obj
                opts.ThresholdQuantile = 0.9  % See filter_noise_peaks docs
                opts.ThresholdMultiplier = 3 % See filter_noise_peaks docs
                opts.SegmentsBounds = [1;length(obj.signal)]; % See filter_noise_peaks docs
                opts.NeighborSize = 2  % See filter_noise_peaks docs
                opts.Display = 0  % See filter_noise_peaks docs
            end
            if(obj.phaseDiscontinuitiesRemoved) % check if it is already done, put some warning, and continue! :)
                warning("removePhaseDiscontinuities already done. Computing once again! :)")
            end

            slowTimePhase_filt = sts2stp(obj,"method","atan");
            unwrapped_phase_diff = compl_diff(diff(slowTimePhase_filt.phase));
            filtered_phase_diff = filter_noise_peaks(unwrapped_phase_diff, ...
                "NeighborSize",opts.NeighborSize, ...
                "Display", opts.Display , ...
                "ThresholdMultiplier",opts.ThresholdMultiplier, ...
                "ThresholdQuantile", opts.ThresholdQuantile, ...
                "SegmentsBounds",opts.SegmentsBounds);

            % for additional return value
            slowTimePhase_filt.phase = cumsum(filtered_phase_diff);
            slowTimePhase_filt.phaseDiscontinuitiesRemoved = 1;

            % actual change of IQ signal
            obj.signal = filter_phase_jumps(obj.signal, unwrapped_phase_diff,filtered_phase_diff);
            obj.phaseDiscontinuitiesRemoved = 1;
        end

        % abstract methods implementations
        function startDateTime = getStartDateTime(obj)
            startDateTime = obj.signalInfo.timeStart;
        end
        function samplingFrequency = getSamplingFrequency(obj)
            if(obj.resamplingWasApplied)
                error("Resampling not supported")
            end
            samplingFrequency = obj.signalInfo.PRF;
        end
        function signal = getSignal(obj)
            signal = obj.signal;
        end

    end

end

