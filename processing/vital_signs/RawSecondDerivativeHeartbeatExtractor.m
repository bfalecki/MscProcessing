classdef RawSecondDerivativeHeartbeatExtractor < handle & TimeFrequencyAnalyzable
    %RAWSECONDDERIVATIVEHEARTBEATEXTRACTOR
    % this method takes the raw signal and computes its second derivative,
    % simillar to 
    % Accurate Radar-Based Heartbeat Measurement Using Higher Harmonic Components
    % Itsuki Iwata, Kimitaka Sumi, Yuji Tanaka, Member, IEEE, and Takuya Sakamoto, Senior Member, IEEE,
    % 2024

    % Does not work with phaser data. Perhaps this simple implementation is
    % incorrect and/or requires better pre-procesing
    properties
        % inputs
        slowTimeSignal % instance of SlowTimeSignal or subclasses, the analyzed signal object reprezenting raw IQ signal
        
        % results after process()
        heartbeatSignal % filtered radial velocity waveform, in [m/s]
    end
    
    methods
        function obj = RawSecondDerivativeHeartbeatExtractor()
            %RAWSECONDDERIVATIVEHEARTBEATEXTRACTOR Construct an instance of this class

        end
        
        function process(obj,slowTimeSignal)
            %Process the data
            % slowTimePhase - instance of SlowTimePhase
            obj.slowTimeSignal = slowTimeSignal;
            obj.heartbeatSignal = abs(diff(diff(slowTimeSignal.signal)));

        end

        function plotResult(obj)
            time_ax = (0:(length(obj.heartbeatSignal)-1))/obj.slowTimeSignal.getSamplingFrequency();
            plot(time_ax, obj.heartbeatSignal,"Color",'k','LineWidth',1.5)
            title("Second-Diff Heartbeat Extraction")
            xlabel("Time [s]")
            ylabel("Amplitude")
        end

        % Abstract methods implementations for TimeFrequencyAnalyzable
        function startDateTime = getStartDateTime(obj)
            startDateTime = obj.slowTimeSignal.signalInfo.timeStart;
        end
        function samplingFrequency = getSamplingFrequency(obj)
            samplingFrequency = obj.slowTimeSignal.getSamplingFrequency();
        end
        function signal = getSignal(obj)
            signal = obj.heartbeatSignal;
        end

    end
end

