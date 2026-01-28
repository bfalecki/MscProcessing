classdef FsstAnalyzer < handle & HeartRateComparable
    %FSSTANALYZER
    % this class acts as a wrapper for functions related to transforming
    % the signal into time-frequency domain using fsst().
    % Tt contains also time-frequency ridge detector using tfridge().
    % It also contains visualization methods.
    
    properties
        % inputs
        timeFrequencyAnalyzable % TimeFrequencyAnalyzable = TimeFrequencyAnalyzable.empty
        FrequencyResolution
        MaximumVisibleFrequency
        WindowWidth

        % results
        synchrosqueezed
        f_ax
        t_ax
        ridge % selected ridge
        ridges % all ridges
        ridge_idx % selected ridge idx
    end
    
    methods
        function obj = FsstAnalyzer(opts)
            %FSSTANALYZER Construct an instance of this class
            arguments
                opts.FrequencyResolution = 1/60; % Desired Frequency Resolution 
                        % (pixel size of freq axis) of the distribution (Hz)
                        % typical value for heart rate is 1 BPM
                opts.MaximumVisibleFrequency = 3; % Maximum visible
                        % frequency on the distribution [Hz]
                        % Typical desired value in case of heart rate
                        % estimation is 3 Hz
                opts.WindowWidth = 4; % FWHM of the gaussian window function [s]
            end
            obj.FrequencyResolution = opts.FrequencyResolution ;
            obj.MaximumVisibleFrequency = opts.MaximumVisibleFrequency ;
            obj.WindowWidth = opts.WindowWidth ;

        end
        
        function transform(obj, timeFrequencyAnalyzable)
            % This method transforms signal using synchrosqueezed short
            % time Fourier transform
            % timeFrequencyAnalyzable - TimeFrequencyAnalyzable instance
            arguments
                obj 
                timeFrequencyAnalyzable TimeFrequencyAnalyzable
            end

            
            obj.timeFrequencyAnalyzable = timeFrequencyAnalyzable;
            [obj.synchrosqueezed,obj.f_ax,obj.t_ax] = synchrosqueezing_general( ...
                obj.timeFrequencyAnalyzable.getSignal(), ...
                obj.timeFrequencyAnalyzable.getSamplingFrequency(),...
                "FrequencyResolution",obj.FrequencyResolution, ...
                "MaximumVisibleFrequency",obj.MaximumVisibleFrequency, ...
                "WindowWidth",obj.WindowWidth);
        end

        function detectRidge(obj, opts)
            % function to find tfridge of the result
            arguments
                obj 
                opts.PossibleLowFrequency =  30/60; % minimum freq. values expected
                opts.PossibleHighFrequency = 180/60; % maximum freq. values expected
                opts.JumpPenalty = 0.02 ; % jump penalty
                opts.NuberOfRidges = 1; % how many ridges to find
                opts.SelectMethod = "first"; % method for selection one tfridge
                        % "lowest" / "first" / "nearest" / "middle"
                opts.DesiredNearestFrequency = [] ; % desired nearest frequency to select tfridge
                        % only when SelectMethod is "nearest"
            end

            if(isempty(opts.DesiredNearestFrequency) && strcmp(opts.SelectMethod, "nearest"))
                error("Need to specify DesiredNearestFrequency!")
            end  

            % Attention! Here we have cut of the  synchrosqueezed and  f_ax
            % variables
            [obj.ridges, obj.synchrosqueezed, obj.f_ax] = find_tfridge( ...
                obj.synchrosqueezed, ...
                obj.f_ax,...
                "JumpPenalty",opts.JumpPenalty, ...
                "NuberOfRidges",opts.NuberOfRidges,...
                "PossibleHighFrequency",opts.PossibleHighFrequency,...
                "PossibleLowFrequency",opts.PossibleLowFrequency);

            % select appriopriate ridge (if multiple choices)
            switch opts.SelectMethod
                case "lowest"
                    [~,obj.ridge_idx] = min(mean(obj.ridges));
                case "first"
                    obj.ridge_idx = 1;
                case "nearest"
                    [~, obj.ridge_idx] =  min(abs(mean(obj.ridges) - opts.DesiredNearestFrequency));
                case "middle"
                    mean_values= mean(obj.ridges);
                    median_mean = median(mean_values);
                    [~, obj.ridge_idx] =  min(abs(mean_values - median_mean));
            end
            obj.ridge = obj.ridges(:,obj.ridge_idx);

        end

        function plotResults(obj,opts)
            % plot Resulting fsst in dB scale
            arguments
                obj 
                opts.QuantileVal = 0.2; % threshold quantile
                opts.AllRidges = 1; % whether to plot all ridges, but only one more prominent
                opts.PlotRidges = 1; % whether to plot any ridges
            end

            f_ax_bpm = obj.f_ax*60;
            ridges_bpm = obj.ridges*60;
            cdata = prep_cdata(obj.synchrosqueezed,"QuantileVal",opts.QuantileVal);
            imagesc(obj.t_ax,f_ax_bpm,cdata); axis xy
            colormap(flip(gray)); 
            c = colorbar;
            c.Label.String = 'Energy [dB]';
            ylabel("Frequency [BPM]"); xlabel("Time [s]");
            title("Synchrosqueezed STFT");
            if(opts.PlotRidges)
                hold on
                plot(obj.t_ax, ridges_bpm(:, 1:end == obj.ridge_idx),'Color','r','LineWidth',1.5,'LineStyle','--')
                if(opts.AllRidges && size(ridges_bpm,2) > 1)
                    plot(obj.t_ax, ridges_bpm(:, 1:end ~= obj.ridge_idx),'Color','g','LineWidth',1.2,'LineStyle','--')
                    legend({'Selected', 'Rejected'})
                end
                hold off
            end
        end

        % Abstract methods implementations for HeartRateComparable
        function heartRate = getHeartRate(obj)% heart rate signal [BPM]
            heartRate = obj.ridge;
        end
        function timeAxisDateTime = getTimeAxisDateTime(obj) % time axis in dateTime format
            timeAxisDateTime = obj.timeFrequencyAnalyzable.getStartDateTime() + seconds(obj.t_ax);
        end
        function timeAxis = getTimeAxis(obj) % time axis in seconds
            timeAxis = obj.t_ax;
        end
    end
end

