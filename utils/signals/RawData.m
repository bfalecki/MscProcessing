classdef RawData
    %RAWDATA Class representing raw data
    
    properties
        data % raw data in a form of matrix, 1st dim = fast time, 2nd dim = slow time
        signalInfo % instance of SignalInfo
    end
    
    methods
        function obj = RawData(data, signalInfo)
            %RAWDATA Construct an instance of this class
            obj.data = data;
            obj.signalInfo = signalInfo;
        end

        function plotMatrix(obj, npulses)
            arguments
                obj 
                npulses = 5000
            end
            npulses_max = min(npulses, size(obj.data,2));
            data2plt = abs(obj.data(:,1:npulses_max));
            plot_surf(data2plt,"","",0,"","gray", [min(data2plt,[],"all") max(data2plt,[],"all")])
            xlabel("Number of Pulse")
            ylabel("Fast Time Sample")
        end
        function plotIQ(obj, npulses)
            arguments
                obj
                npulses = 500
            end
            npulses_max = min(npulses, size(obj.data,2));
            plot(real(obj.data(:,1:npulses_max)),'b')
            hold on
            plot(imag(obj.data(:,1:npulses_max)),'r')
            hold off
        end
    end
end

