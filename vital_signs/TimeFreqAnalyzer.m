classdef TimeFreqAnalyzer < handle & HeartRateComparable
    %TIMEFREQANALYZER
    % this class acts as a wrapper for functions related to transforming
    % the signal into time-frequency domain using fsst() or stft.
    % Tt contains also time-frequency ridge detector using tfridge().
    % It also contains visualization methods.
    
    properties
        % inputs
        timeFrequencyAnalyzable % TimeFrequencyAnalyzable = TimeFrequencyAnalyzable.empty
        FrequencyResolution
        MaximumVisibleFrequency
        WindowWidth
        Synchrosqueezed

        % results
        tfdistribution
        f_ax
        t_ax

        ridge % selected ridge
        ridges % all ridges
        ridge_idx % selected ridge idx

        % peaks (no memory)
        freqLocs % selected frequencies of heart rate peaks [Hz]
        upperFreqLocs % frequencies of heart rate upper harmonic [Hz], if detectPeaks(Method=="distanceBased")
        lowerFreqLocs % frequencies of heart rate lower harmonic [Hz], if detectPeaks(Method=="distanceBased")

        heartRateOutput % "ridge" (default) / "peaks" - choose port to HeartRateComparable interface
    end
    
    methods
        function obj = TimeFreqAnalyzer(opts)
            %TimeFreqAnalyzer Construct an instance of this class
            arguments
                opts.FrequencyResolution = 1/60; % Desired Frequency Resolution 
                        % (pixel size of freq axis) of the distribution (Hz)
                        % typical value for heart rate is 1 BPM
                opts.MaximumVisibleFrequency = 3; % Maximum visible
                        % frequency on the distribution [Hz]
                        % Typical desired value in case of heart rate
                        % estimation is 3 Hz
                opts.WindowWidth = 4; % FWHM of the gaussian window function [s]
                opts.Synchrosqueezed = 0; % use fsst function insted of stft
            end
            obj.FrequencyResolution = opts.FrequencyResolution ;
            obj.MaximumVisibleFrequency = opts.MaximumVisibleFrequency ;
            obj.WindowWidth = opts.WindowWidth ;
            obj.Synchrosqueezed = opts.Synchrosqueezed;
            obj.heartRateOutput = "ridge";

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
            if(obj.Synchrosqueezed)
                [obj.tfdistribution,obj.f_ax,obj.t_ax] = synchrosqueezing_general( ...
                    obj.timeFrequencyAnalyzable.getSignal(), ...
                    obj.timeFrequencyAnalyzable.getSamplingFrequency(),...
                    "FrequencyResolution",obj.FrequencyResolution, ...
                    "MaximumVisibleFrequency",obj.MaximumVisibleFrequency, ...
                    "WindowWidth",obj.WindowWidth);
            else
                [obj.tfdistribution,obj.f_ax,obj.t_ax] = stft_general( ...
                    obj.timeFrequencyAnalyzable.getSignal(), ...
                    obj.timeFrequencyAnalyzable.getSamplingFrequency(), ...
                    "FrequencyResolution",obj.FrequencyResolution, ...
                    "MaximumVisibleFrequency",obj.MaximumVisibleFrequency, ...
                    "WindowWidth",obj.WindowWidth);
            end


        end

        function setHeartRateOutput(obj,outputType)
            arguments
                obj 
                outputType % "ridge" / "peaks"
            end
            if(strcmp(outputType,  "ridge"))
                obj.heartRateOutput = "ridge";
            elseif(strcmp(outputType,  "peaks"))
                obj.heartRateOutput = "peaks";
            else
                error("Invalid type: " + outputType)
            end
        end

        function detectPeaks(obj, opts)
            % something like detectRidge, but without memory
            arguments
                obj 
                opts.Method % "highest" / "lower" / "middle" / "distanceBased"
                opts.ExactDistance % [Hz], input for findOptimumPeak if Method=="distanceBased"
                opts.DistanceTolerance % Hz, input for findOptimumPeak if Method=="distanceBased"
            end
            if(strcmp(opts.Method, "highest"))
                obj.upperFreqLocs = nan;
                obj.lowerFreqLocs = nan;
                [~, locs] = findHighestPeak(abs(obj.tfdistribution));
                obj.freqLocs = obj.f_ax(fillmissing(locs,"constant",1));
            elseif(strcmp(opts.Method, "lower"))
                obj.upperFreqLocs = nan;
                obj.lowerFreqLocs = nan;
                [~, locs] = findLowerPeak(abs(obj.tfdistribution));
                obj.freqLocs = obj.f_ax(fillmissing(locs,"constant",1));
            elseif(strcmp(opts.Method, "middle"))
                obj.upperFreqLocs = nan;
                obj.lowerFreqLocs = nan;
                [~, locs] = findMiddlePeak(abs(obj.tfdistribution));
                obj.freqLocs = obj.f_ax(fillmissing(locs,"constant",1));
            elseif(strcmp(opts.Method, "distanceBased"))
                freqStepSize = obj.f_ax(2) - obj.f_ax(1);
                distanceSamples = round(opts.ExactDistance/freqStepSize);
                distToleranceSamples = round(opts.DistanceTolerance/freqStepSize);
                [~,locs, upperLocs, lowerLocs] = findOptimumPeak(abs(obj.tfdistribution),distanceSamples, distToleranceSamples);
                obj.freqLocs = obj.f_ax(fillmissing(locs,"constant",1));
                obj.upperFreqLocs = obj.f_ax(fillmissing(upperLocs,"constant",1));
                obj.lowerFreqLocs = obj.f_ax(fillmissing(lowerLocs,"constant",1));
            else
                error("Unknown Method: " + opts.Method)
            end
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
            [obj.ridges, obj.tfdistribution, obj.f_ax] = find_tfridge( ...
                obj.tfdistribution, ...
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
                opts.PlotPeaks = 1; % whether to plot no-memory ridges (peaks)
                opts.PlotPeaksHarmonics = 1; % whether to plot no-memory upperFreqLocs and lowerFreqLocs
            end

            f_ax_bpm = obj.f_ax*60;
            ridges_bpm = obj.ridges*60;
            cdata = prep_cdata(obj.tfdistribution,"QuantileVal",opts.QuantileVal);
            imagesc(obj.t_ax,f_ax_bpm,cdata); axis xy
            colormap(flip(gray)); 
            c = colorbar;
            c.Label.String = 'Energy [dB]';
            ylabel("Frequency [BPM]"); xlabel("Time [s]");
            title("Synchrosqueezed STFT");
            legendEntries = strings([]);
            if(opts.PlotRidges)
                hold on
                plot(obj.t_ax, ridges_bpm(:, 1:end == obj.ridge_idx),'Color','r','LineWidth',1.5,'LineStyle','--')
                if(opts.AllRidges && size(ridges_bpm,2) > 1)
                    plot(obj.t_ax, ridges_bpm(:, 1:end ~= obj.ridge_idx),'Color','g','LineWidth',1.2,'LineStyle','--')
                    legendEntries = [legendEntries, "Selected Ridge", "Rejected Ridges", strings(1,size(ridges_bpm,2)-2)];
                end
                hold off
            end
            if(opts.PlotPeaks)
                hold on
                plot(obj.t_ax, obj.freqLocs*60, '*r')
                legendEntries = [legendEntries, "Selected Peaks"];
                if(opts.PlotPeaksHarmonics && ~any(isnan(obj.lowerFreqLocs)))
                    plot(obj.t_ax,obj.lowerFreqLocs*60, '*g')
                    plot(obj.t_ax,obj.upperFreqLocs*60, '*b')
                    legendEntries = [legendEntries, "Lower Peaks", "Upper Peaks"];
                end
                hold off
            end
            legend(legendEntries)
        end

        % Abstract methods implementations for HeartRateComparable
        function heartRate = getHeartRate(obj)% heart rate signal [BPM]
            if(strcmp(obj.heartRateOutput, "ridge"))
                heartRate = obj.ridge;
            elseif(strcmp(obj.heartRateOutput, "peaks"))
                heartRate = obj.freqLocs;
            end
        end
        function timeAxisDateTime = getTimeAxisDateTime(obj) % time axis in dateTime format
            timeAxisDateTime = obj.timeFrequencyAnalyzable.getStartDateTime() + seconds(obj.t_ax);
        end
        function timeAxis = getTimeAxis(obj) % time axis in seconds
            timeAxis = obj.t_ax;
        end
    end
end

