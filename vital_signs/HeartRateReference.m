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

        function rms_error = calucateError(obj, heartRateComparables)
            % calculate error between heart rates
            arguments
                obj 
                heartRateComparables
            end
            fs = 1/seconds(mean(diff(obj.timeAxisDateTime)));
            time_ax_dt = obj.getTimeAxisDateTime;
            time_start = time_ax_dt(1);
            rms_error = zeros(1,length(heartRateComparables));

            for k = 1:length(heartRateComparables)
                fs_des = 1/seconds(mean(diff(heartRateComparables(k).getTimeAxisDateTime)));
                time_ax_dt_des = heartRateComparables(k).getTimeAxisDateTime;
                time_start_des = time_ax_dt_des(1);
                hr_adj = adjustSampling(obj.heartRate, fs,fs_des,time_start, time_start_des,'spline');
                hr_adj = hr_adj(1:length(heartRateComparables(k).getHeartRate));
                figure(4444)
                plot(hr_adj)
                hold on
                plot(heartRateComparables(k).getHeartRate*60)
                hold off
                rms_error(k) = rms(hr_adj - heartRateComparables(k).getHeartRate*60);% in BPM;
            end

        end
    end
end

