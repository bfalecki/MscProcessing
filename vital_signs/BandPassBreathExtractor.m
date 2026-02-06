classdef BandPassBreathExtractor < handle & TimeFrequencyAnalyzable
    %BandPassBreathExtractor 
    % This method is simple way to filter breath signal
    
    properties
        % parameters
        PassBand
        UpsamplingFactor
        
        % inputs
        slowTimePhase % instance of SlowTimePhase or subclasses, the analyzed signal object

        % results after process()
        breathSignal % filtered displacement waveform, in [m]
        actual_fs % actual sampling frequency after set_fs function
        t_resampled % time axis after set_fs function
    end
    
    methods
        function obj = BandPassBreathExtractor(opts)
            %BandPassBreathExtractor Construct an instance of this class
            arguments
                opts.PassBand = [0.05 1] % corresponds to typical breath rate boundaries [Hz]
                opts.UpsamplingFactor = 4; % how reduntant the sampling rate needs to be
                        % if set to 1, the lowpass filter can be skept for
                        % faster computation
            end
            obj.PassBand = opts.PassBand;
            obj.UpsamplingFactor = opts.UpsamplingFactor;
        end
        
        function process(obj,slowTimePhase)
            %Process the data
            % slowTimePhase - instance of SlowTimePhase
            obj.slowTimePhase = slowTimePhase;

            % we need to set proper fs
            desired_fs = obj.PassBand(2)*2 * obj.UpsamplingFactor;

            if(slowTimePhase.resamplingWasApplied)
                error("Resampling not supported")
            end
            % transform from phase to displacement in [m]
            obj.breathSignal = phase2displ(slowTimePhase.phase, slowTimePhase.signalInfo.carrierFrequency);

            % reducing sampling frequency
            [obj.breathSignal,obj.actual_fs, obj.t_resampled] = set_fs(obj.breathSignal, slowTimePhase.signalInfo.PRF,desired_fs);
            
            % high pass filter
            padlength = 50; % this padding removes the edge effect of filter
            obj.breathSignal = fillmissing(padarray(obj.breathSignal(:),padlength,nan, "post").', "nearest");
            obj.breathSignal = highpass(obj.breathSignal, obj.PassBand(1) / (obj.actual_fs/2));
            obj.breathSignal = obj.breathSignal(1:length(obj.breathSignal)-padlength);
            % for faster implementation, lowpass can be skept by using
            % lower desired_fs value
            if(obj.UpsamplingFactor - 1 > 0.05)
                obj.breathSignal = lowpass(obj.breathSignal, obj.PassBand(2) / (obj.actual_fs/2));
            end

        end

        function plotResult(obj)
            plot(obj.t_resampled, obj.breathSignal*1e3,"Color",'k','LineWidth',1.5)
            title("Filter-Based Breath Extraction")
            xlabel("Time [s]")
            ylabel("Displacement [mm]")
        end

        % Abstract methods implementations for TimeFrequencyAnalyzable
        function startDateTime = getStartDateTime(obj)
            startDateTime = obj.slowTimePhase.signalInfo.timeStart;
        end
        function samplingFrequency = getSamplingFrequency(obj)
            samplingFrequency = obj.actual_fs;
        end

        function signal = getSignal(obj)
            signal = obj.breathSignal;
        end


    end
end

