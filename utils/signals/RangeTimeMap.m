classdef RangeTimeMap
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        rangeAxis % range axis vector [m]
        timeAxis % slow time axis vector [s]
        data % matrix, first dim = fast time FFT, seconds dim = slow time
        signalInfo % instance of SignalInfo
    end
    
    methods
        function obj = RangeTimeMap(data,rangeAxis,timeAxis,signalInfo)
            arguments
                data 
                rangeAxis 
                timeAxis 
                signalInfo 
            end
            obj.data = data;
            obj.rangeAxis = rangeAxis;
            obj.timeAxis = timeAxis;
            obj.signalInfo = signalInfo;
        end
        
    end
end

