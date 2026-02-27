classdef  (Abstract) SlowTimeSignalAny < handle & TimeFrequencyAnalyzable
    %SLOWTIMESIGNALANY kind of abstract class as a base
    
    properties
        rangeCellNumber % natural scalar (can be 2dim vector), from which range cell the signal originates, informative
        desiredRangeCellMeters % [m] scalar (can be 2dim vector), from which range cell in meters the signal originates, informative
        actualRangeCellsMeters % [m], (scalar or N dim vector) which range cells are actually accessed
        resamplingWasApplied % 1/0, if band reducing was applied in slow time, informative
        phaseDiscontinuitiesRemoved % 1/0, if phase discontinuities were removed using filter_phase_jumps function
        signalInfo % instance of SignalInfo class
    end
    
    methods
        function obj = SlowTimeSignalAny()
            %SLOWTIMESIGNALANY Construct an instance of this class
        end
        
        function initialize(obj,opts)
            %   Set the values
            arguments
                obj
                opts.rangeCellNumber = [];
                opts.desiredRangeCellMeters = [];
                opts.actualRangeCellsMeters = [];
                opts.signalInfo = obj.signalInfo;
                opts.resamplingWasApplied = 0;
                opts.phaseDiscontinuitiesRemoved = 0;
            end
            obj.rangeCellNumber = opts.rangeCellNumber;
            obj.desiredRangeCellMeters =opts.desiredRangeCellMeters;
            obj.actualRangeCellsMeters = opts.actualRangeCellsMeters;
            obj.signalInfo = opts.signalInfo;
            obj.resamplingWasApplied = opts.resamplingWasApplied;
            obj.phaseDiscontinuitiesRemoved = opts.phaseDiscontinuitiesRemoved;
        end

        function relative_idx = selectSingleCell(obj, opts)
            % change the object to cantain only a single range cell signal
            arguments
                obj
                opts.rangeCellMeters = [] % desired range cell to select [m]
                opts.autoSelectMethod = "maxrms" % if desired range cell not specified, then auto-selection
                opts.WindowWidth = inf % rectangular window width of rms for range-cell auto-selection [s]
            end
            if(isempty(opts.rangeCellMeters))
                if(strcmp(opts.autoSelectMethod,"maxrms"))
                    if(opts.WindowWidth == inf)
                        [~,relative_idx] = max(rms(abs(obj.getSignal).', [],1));
                    else
                        % moving RMS with rectangular window
                        % now we have vector of indices
                        windLen = round(opts.WindowWidth * obj.getSamplingFrequency);
                        movingRms = signal.internal.builtin.movrms(abs(obj.getSignal).',windLen);
                        if(any(size(movingRms) == 1))
                            movingRms = movingRms(:);
                        end
                        [~,relative_idx] = max(movingRms,[],2);
                        relative_idx = relative_idx.';
                    end
                end
                obj.desiredRangeCellMeters = nan;
            else
                if(isscalar(opts.rangeCellMeters))
                    [~,relative_idx] = min(abs(obj.actualRangeCellsMeters - opts.rangeCellMeters));
                else % each idx separately
                    [~,relative_idx] = min(abs(obj.actualRangeCellsMeters.' - opts.rangeCellMeters),[], 1);
                end
                obj.desiredRangeCellMeters = opts.rangeCellMeters;
            end


            if(isvector(relative_idx) && all(relative_idx == 1))
                % do nothing, already selected single range cell
            else
                rangeCellNumbersAll = obj.rangeCellNumber(1):obj.rangeCellNumber(end);
                obj.rangeCellNumber = rangeCellNumbersAll(relative_idx);
                obj.actualRangeCellsMeters = obj.actualRangeCellsMeters(relative_idx);
            end

            

            currentSignal = obj.getSignal();
            if(isscalar(relative_idx))
                obj.setSignal(currentSignal(relative_idx, :));
            else
                % changing range cell
                full_idx = (relative_idx - 1)*size(obj.getSignal,2) + (1:size(obj.getSignal,2));
                signalTransp = obj.getSignal.';
                signalExtracted = signalTransp(full_idx);
                if(isvector(signalExtracted)) % one dimension
                    signalExtracted = signalExtracted(:).';
                end
                obj.setSignal(signalExtracted);
            end
        end

        function plotSelectedRangeCell(obj)
            if(size(obj.getSignal,1) ~= 1)
                error("Range cell not auto-selected")
            end
            time = (0:length(obj.getSignal)-1)/obj.getSamplingFrequency;
            plot(time, obj.actualRangeCellsMeters);
            xlabel("Time [s]")
            ylabel("Range Cell [m]")
            ylim([0 4])
        end

        function plotSpectrum(obj, opts)
            % plot spectrum of phase
            arguments
                obj
                opts.differentiated = 0; % whether to differentiate phase
            end
            if(opts.differentiated == 1)
                signal2Analyze = obj.getSignal.';
            else
                signal2Analyze = diff(obj.getSignal.');
            end

            % signal2Analyze = signal2Analyze - mean(signal2Analyze);
            signalSpectrum = abs(fft(signal2Analyze));
            freq_axis = linspace(0,obj.getSamplingFrequency, size(signalSpectrum,1));
            plot(freq_axis,signalSpectrum)
            if(~isscalar(obj.actualRangeCellsMeters))
                legend(string(obj.actualRangeCellsMeters) + " m")
            end
            xlabel("Frequency [Hz]")
            ylabel("Amplitude")
            % real-valued signal
            if(~any(imag(obj.getSignal),"all"))
                xlim([0 obj.getSamplingFrequency/2])
            end

        end

    end

    methods (Abstract)
        setSignal(obj,signal); % set signal
    end
end

