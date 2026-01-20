classdef (Abstract) HeartRateComparable < handle
    %HEARTRATECOMPARABLE Summary of this class goes here
    %   Detailed explanation goes here
    
    
    methods (Abstract)
        heartRate = getHeartRate(obj)  % heart rate signal [BPM]
        timeAxisDateTime = getTimeAxisDateTime(obj) % time axis in dateTime format
        timeAxis = getTimeAxis(obj) % time axis in seconds
    end
end

