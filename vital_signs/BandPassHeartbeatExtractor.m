classdef BandPassHeartbeatExtractor < handle & TimeFrequencyAnalyzable
    %BANDPASSHEARTBEATEXTRACTOR 
    % This function is the simplest way ever to extract heartbeat signal
    % It can state as a reference method for other, more complex methods to
    % clearly see whether there is an improvement or not.
    
    properties
        % parameters
        PassBand
        UpsamplingFactor
        
        % inputs
        slowTimePhase % instance of SlowTimePhase or subclasses, the analyzed signal object

        % results after process()
        heartbeatSignal % filtered radial velocity waveform, in [m/s]
        actual_fs % actual sampling frequency after set_fs function
        t_resampled % time axis after set_fs function
    end
    
    methods
        function obj = BandPassHeartbeatExtractor(opts)
            %BANDPASSHEARTBEATEXTRACTOR Construct an instance of this class
            arguments
                opts.PassBand = [0.9 1.5] % corresponds to typical heart rate boundaries [Hz]
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
            % transform from phase to velocity in [m/s]
            obj.heartbeatSignal = phase2fdoppler(slowTimePhase.phase, slowTimePhase.signalInfo.PRF);
            obj.heartbeatSignal = fdoppler2vel(obj.heartbeatSignal, slowTimePhase.signalInfo.carrierFrequency);

            % reducing sampling frequency
            [obj.heartbeatSignal,obj.actual_fs, obj.t_resampled]= set_fs(obj.heartbeatSignal, slowTimePhase.signalInfo.PRF,desired_fs);
            
            % high pass filter
            obj.heartbeatSignal = highpass(obj.heartbeatSignal, obj.PassBand(1) / (obj.actual_fs/2));
            % for faster implementation, lowpass can be skept by using
            % lower desired_fs value
            if(obj.UpsamplingFactor - 1 > 0.05)
                obj.heartbeatSignal = lowpass(obj.heartbeatSignal, obj.PassBand(2) / (obj.actual_fs/2));
            end

        end

        function plotResult(obj)
            plot(obj.t_resampled, obj.heartbeatSignal,"Color",'k','LineWidth',1.5)
            title("Filter-Based Heartbeat Extraction")
            xlabel("Time [s]")
            ylabel("Velocity [m/s]")
        end

        % Abstract methods implementations for TimeFrequencyAnalyzable
        function startDateTime = getStartDateTime(obj)
            startDateTime = obj.slowTimePhase.signalInfo.timeStart;
        end
        function samplingFrequency = getSamplingFrequency(obj)
            samplingFrequency = obj.actual_fs;
        end
        function signal = getSignal(obj)
            signal = obj.heartbeatSignal;
        end

    end
end

