classdef (Abstract) Predictable < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods
        function obj = Predictable()
            
        end
    end
    methods (Abstract)
        [startIndices, endIndices] = getSegmentsStartsEnds(obj) % get segment start-end indices
        signalToPredict = getSignalToPredict(obj) % double vector
        segmentDuration = getSegmentDuration(obj) % [s]
        samplingFrequency = getSamplingFrequency(obj) % Hz
    end
end

