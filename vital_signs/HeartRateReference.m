classdef HeartRateReference < handle & HeartRateComparable
    %HEARTRATEREFERENCE
    % A class for the representation of reference hear rate measurement
    % using not-radar sensor (Kalenji)
    
    properties
        heartRate
        timeAxisDateTime
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

            colors = ["#FF4500", "#008000", "c"];

            zero_time =  obj.getTimeAxisAdjusted();
            zero_time = zero_time(1);
            plot(obj.getTimeAxis() - zero_time, obj.getHeartRate(), 'b*')
            hold on
            legendEnties = "Reference Sensor";
            if(opts.showAdjusted)
                plot(obj.getTimeAxisAdjusted() - zero_time, obj.adjustedHeartRate, Color="#00BFFF", LineWidth=1.2, LineStyle='--')
                legendEnties = [legendEnties "Reference Interpol."];
            end
            extractorNames = string([]);
            for k = 1:length(opts.otherResults)
                if(iscell(opts.otherResults))
                    tempResult = opts.otherResults{k};
                else
                    tempResult = opts.otherResults(k);
                end
                [~, timeStart] = getTimeAxis(obj);
                tax_Sec = seconds(tempResult.getTimeAxisDateTime() - timeStart);
                plot(tax_Sec - zero_time, tempResult.getHeartRate()*60,Color=colors(k), LineWidth=1.2)
                extractorNames(k) = string(class(tempResult.timeFrequencyAnalyzable));
            end
            legendEnties = [legendEnties extractorNames];
            legend(legendEnties)
            hold off
            xlabel("Time [s]"); ylabel("Heart Rate [BPM]")
        end

        % Abstract methods implementations
        function heartRate = getHeartRate(obj)% heart rate signal [BPM]
            heartRate = obj.heartRate;
        end
        function timeAxisDateTime = getTimeAxisDateTime(obj) % time axis in dateTime format
            timeAxisDateTime = obj.timeAxisDateTime; 
        end
        function [timeAxSeconds, timeStart] = getTimeAxis(obj) % time axis in seconds
            timeStart = obj.getTimeAxisDateTime();
            timeStart = timeStart(1);
            timeAxSeconds = seconds(obj.getTimeAxisDateTime() - timeStart);
        end
        function [timeAxSeconds, timeStart] = getTimeAxisAdjusted(obj) % time axis in seconds (adjusted)
            [~, timeStart] = getTimeAxis(obj);
            timeAxSeconds = seconds(obj.adjustedTimeAxis - timeStart);
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

