classdef (Abstract) TimeFrequencyAnalyzable < handle
    %TIMEFREQUENCYANALYZABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    % % TO DO: remove this part, leave only abstract methods
    % properties
    %     signalForTfa
    %     samplingFrequencyForTfa
    %     startDateTime
    % end
    methods (Abstract)
        signal = getSignal(obj) % vector of values to analyze
        samplingFrequency = getSamplingFrequency(obj) % sampling frequency [Hz]
        startDateTime = getStartDateTime %  start time in datetime format
    end
end

