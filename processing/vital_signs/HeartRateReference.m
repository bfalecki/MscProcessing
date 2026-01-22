classdef HeartRateReference < handle & HeartRateComparable
    %HEARTRATEREFERENCE
    % A class for the representation of reference hear rate measurement
    % using not-radar sensor (Kalenji)
    
    properties
        heartRate
        timeAxisDateTime
        timeAxis
        ManualTimeShift
        path
    end
    
    methods
        function obj = HeartRateReference(path, opts)
            %HEARTRATEREFERENCE Construct an instance of this class
            arguments
                path % path to .fit file
                opts.ManualTimeShift = 0 % Manual time zone compensation [hours], typically + hours(1)
            end
            obj.path = path;
            obj.ManualTimeShift = hours(opts.ManualTimeShift);
            [obj.heartRate, obj.timeAxisDateTime] = parse_fit(path);
            obj.timeAxisDateTime = obj.timeAxisDateTime + obj.ManualTimeShift; % UTC fix
        end

        function plot(obj, opts)
            arguments
                obj 
                opts.otherResults % object implementing HeartRateComparable interface
            end
            plot(obj.getTimeAxisDateTime(), obj.getHeartRate())
            hold on
            extractorNames = string([]);
            for k = 1:length(opts.otherResults)
                plot(opts.otherResults(k).getTimeAxisDateTime(), opts.otherResults(k).getHeartRate()*60)
                extractorNames(k) = string(class(opts.otherResults(k).timeFrequencyAnalyzable));
            end
            legend(["Reference", extractorNames])
            hold off
        end

        % Abstract methods implementations
        function heartRate = getHeartRate(obj)% heart rate signal [BPM]
            heartRate = obj.heartRate;
        end
        function timeAxisDateTime = getTimeAxisDateTime(obj) % time axis in dateTime format
            timeAxisDateTime = obj.timeAxisDateTime; 
        end
        function timeAxis = getTimeAxis(obj) % time axis in seconds
            timeAxis = obj.timeAxis;
        end
    end
end

