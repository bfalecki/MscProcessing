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

        function plotMap(obj, npulses_max)
            arguments
                obj 
                npulses_max = 5000 % max number of pulses to plot (from the beggining)
            end
            npulses_max(npulses_max > size(obj.data,2)) = size(obj.data,2);
            plot_surf(obj.data(:,1:npulses_max),obj.timeAxis, obj.rangeAxis)
            xlabel("Slow Time [s]")
            ylabel("Range [m]")
        end
        
    end
end

