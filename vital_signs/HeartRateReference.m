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
        adjustedHeartRate % adjusted heart rate form the last call of calucateError function
        adjustedTimeStart
        adjustedTimeAxis
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
                opts.otherResults % object implementing HeartRateComparable interface, scalar / vector / cell
                opts.showAdjusted = 1
            end
            plot(obj.getTimeAxisDateTime(), obj.getHeartRate(), 'b*')
            hold on
            legendEnties = "Reference";
            if(opts.showAdjusted)
                plot(obj.adjustedTimeAxis, obj.adjustedHeartRate, "b--")
                legendEnties = [legendEnties "Reference Adjusted"];
            end
            extractorNames = string([]);
            for k = 1:length(opts.otherResults)
                if(iscell(opts.otherResults))
                    tempResult = opts.otherResults{k};
                else
                    tempResult = opts.otherResults(k);
                end
                plot(tempResult.getTimeAxisDateTime(), tempResult.getHeartRate()*60)
                extractorNames(k) = string(class(tempResult.timeFrequencyAnalyzable));
            end
            legendEnties = [legendEnties extractorNames];
            legend(legendEnties)
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
                if(iscell(heartRateComparables))
                    tempHrc = heartRateComparables{k};
                else
                    tempHrc = heartRateComparables(k);
                end
                fs_des = 1/seconds(mean(diff(tempHrc.getTimeAxisDateTime)));
                time_ax_dt_des = tempHrc.getTimeAxisDateTime;
                time_start_des = time_ax_dt_des(1);
                obj.adjustedTimeStart = time_start_des;
                obj.adjustedHeartRate = adjustSampling(obj.heartRate, fs,fs_des,time_start, time_start_des,'spline');
                obj.adjustedHeartRate = obj.adjustedHeartRate(1:length(tempHrc.getHeartRate));
                obj.adjustedTimeAxis = time_ax_dt_des;
                rms_error(k) = rms(obj.adjustedHeartRate - tempHrc.getHeartRate*60);% in BPM;
                % figure(4444)
                % plot(hr_adj)
                % hold on
                % plot(tempHrc.getHeartRate*60)
                % hold off

            end

        end
    end
end

