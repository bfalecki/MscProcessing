classdef ResultsCombiner < handle & TimeFrequencyAnalyzable & Predictable
    %RESULTSCOMBINER 
    % This utility can combine the signal from two different signals
    
    properties
        % input
        tfa1 % TimeFrequencyAnalyzable 1
        tfa2 % TimeFrequencyAnalyzable 1
        weight1 % weight of signal 1
        weight2 % weight of signal 2
        timeDelay2 % time delay of tfa2 relative to tfa1 [s] (can be negative)
        estimateDelay % 0/1 whether to estimate the delay relative to timeDelay2, based on the correlation
        estimateSign % whether to choose better sign of weight2

        combinedSignal % Time domain combined signal
        samplingFrequency % after resampling
        startDateTime
        sig1Adj
        sig2Adj % adjustment of sampling rate, time delay, and sampling modulation
        sig2original % only amplitude and sampling rate adjustment

        % input to adjustment parameters estimation
        windowWidth % FWHM [s], gaussian window for signals correlation
        windowStep % slide step of window [s]
        maxAllowableShift % [s], both side

        % estimated adjustment parameters
        shifts
        inversionWeigths
        windowTimeCenters



    end
    
    methods
        function obj = ResultsCombiner()
            %RESULTSCOMBINER Construct an instance of this class
            obj.furtherAnalysisOutput = "nonpredicted";
        end

        function combine(obj,tfa1,tfa2,opts)
            arguments
                obj
                tfa1 TimeFrequencyAnalyzable
                tfa2 TimeFrequencyAnalyzable
                opts.weights = [1 1]
                opts.timeDelay2 = 0
                opts.estimateSign = 0;
                opts.estimateDelay = 0;
                opts.windowWidth = 5;
                opts.windowStep  = 2.5;
                opts.maxAllowableShift = 0.4;
            end
            obj.tfa1 = tfa1;
            obj.tfa2 = tfa2;
            obj.weight1 = opts.weights(1);
            obj.weight2 = opts.weights(2);
            obj.timeDelay2 = opts.timeDelay2;
            obj.estimateSign = opts.estimateSign;
            obj.estimateDelay = opts.estimateDelay;
            obj.windowWidth = opts.windowWidth ;
            obj.windowStep = opts.windowStep ;
            obj.maxAllowableShift = opts.maxAllowableShift ;

            % adjust sampling frequency
            obj.samplingFrequency = max([tfa1.getSamplingFrequency() tfa2.getSamplingFrequency()]);
            delayedStart2 = tfa2.getStartDateTime() + seconds(obj.timeDelay2);
            obj.startDateTime = min([tfa1.getStartDateTime() delayedStart2]);

            desiredDtStart = obj.startDateTime;
            desiredFs = obj.samplingFrequency;
            method = "spline";

            sig1 = adjustSampling(tfa1.getSignal(),tfa1.getSamplingFrequency(),desiredFs,tfa1.getStartDateTime(),desiredDtStart,method);
            sig2 = adjustSampling(tfa2.getSignal(),tfa2.getSamplingFrequency(),desiredFs,delayedStart2,desiredDtStart,method);
            obj.sig2original = adjustSampling(tfa2.getSignal(),tfa2.getSamplingFrequency(),desiredFs,tfa2.getStartDateTime(),desiredDtStart,method);

            maxLen = min([length(sig1) length(sig2)]);
            obj.sig1Adj = sig1(1:maxLen);
            obj.sig2Adj = sig2(1:maxLen);

            % normalization
            obj.sig1Adj = obj.sig1Adj / rms(obj.sig1Adj);
            obj.sig2Adj = obj.sig2Adj / rms(obj.sig2Adj);
            obj.sig2original = obj.sig2original / rms(obj.sig2original);
            obj.sig1Adj = obj.sig1Adj - mean(obj.sig1Adj);
            obj.sig2Adj = obj.sig2Adj - mean(obj.sig2Adj);
            obj.sig2original = obj.sig2original - mean(obj.sig2original);


            obj.sig1Adj = obj.sig1Adj*obj.weight1;
            obj.sig2Adj = obj.sig2Adj*obj.weight2;
            if(obj.estimateDelay)
                % sign and delay estimation
                %  with sliding window, for example 5 s FWHM and 2.5 s step
                %   - do xcorr, find position and max value

                [obj.windowTimeCenters, peakVals, peakShifts, valleyVals, valleyShifts, timeAxis] =...
                    slidingWindowCorr(obj.sig1Adj, obj.sig2Adj,obj.getSamplingFrequency, ...
                    obj.windowWidth, obj.windowStep, obj.maxAllowableShift);
                [obj.shifts,obj.inversionWeigths] = selectBestSamplingShifts(peakVals, peakShifts, valleyVals, valleyShifts, obj.estimateSign);
                obj.sig2Adj = modulateSampling(obj.sig2Adj, timeAxis, obj.shifts, obj.windowTimeCenters, obj.inversionWeigths);
            end
            

            % choose higher peak within desired max shifts of e.g. +- 0.3s


            obj.combinedSignal = obj.sig1Adj + obj.sig2Adj;
        end

        function plotResult(obj, opts)

            arguments
                obj 
                opts.PlotCombined = 1;
                opts.PlotSig1 = 1;
                opts.PlotSig2Adjusted = 1;
                opts.PlotSig2Sign = 1;
                opts.PlotSIg2Original = 1;
                opts.PlotPredicted = 0;
            end

            time_ax = (0:(length(obj.getSignal())-1)) /  obj.getSamplingFrequency();
            time_ax_sig2original = (0:(length(obj.sig2original)-1)) /  obj.getSamplingFrequency();
            legendEntries = strings([]);
            if(opts.PlotCombined)
                if(opts.PlotPredicted)
                    combinedSignalWithBreaks = obj.combinedSignal;
                    combinedSignalWithBreaks(obj.predictedIdxes) = nan;
                    plot(time_ax, combinedSignalWithBreaks, Color='k',LineWidth=1.5)
                else
                    plot(time_ax, obj.combinedSignal, Color='k',LineWidth=1.5)
                end
                legendEntries(end+1) = "Combined";
                hold on
            end
            if(opts.PlotSig1)
                plot(time_ax, obj.sig1Adj, Color='b',LineWidth=1)
                legendEntries(end+1) = string(class(obj.tfa1));
                hold on
            end
            if(opts.PlotSig2Adjusted)
                plot(time_ax, obj.sig2Adj, Color='r',LineWidth=1)
                legendEntries(end+1) = string(class(obj.tfa2)) + " adj.";
                hold on
            end
            if(opts.PlotSIg2Original)
                plot(time_ax_sig2original, obj.sig2original, Color='r',LineStyle='--')
                legendEntries(end+1) = string(class(obj.tfa2)) + " orig.";
                hold on
            end
            if(opts.PlotSig2Sign && obj.estimateSign)
                plot(obj.windowTimeCenters,obj.inversionWeigths, Color='g',LineStyle='--')
                legendEntries(end+1) = string(class(obj.tfa2)) + " sign";
                hold on
            end
            if(opts.PlotPredicted && ~isempty(obj.getPredicted))
                plot(time_ax, obj.getPredicted, Color='k',LineStyle='-.')
                legendEntries(end+1) = "Combined Predicted";
                hold on
            end
            hold off
            legend(legendEntries)

        end

        function plotEstimatedDelay(obj)
            plot(obj.windowTimeCenters, -obj.shifts)
            xlabel("Time [s]")
            ylabel("Delay [s]")
            title("Estimated delay of " + string(class(obj.tfa2)))
        end
        
        % Abstract methods implementations for TimeFrequencyAnalyzable
        function startDateTime = getStartDateTime(obj)
            startDateTime = obj.startDateTime;
        end
        function samplingFrequency = getSamplingFrequency(obj)
            samplingFrequency = obj.samplingFrequency;
        end

        function [startIndices, endIndices] = getSegmentsStartsEnds(obj)
            sampling_freq_ratio = obj.getSamplingFrequency / obj.tfa1.getSamplingFrequency;
            [startIndices_temp, endIndices_temp] = obj.tfa1.getSegmentsStartsEnds;

            % NOT TESTED, possible errors
            time_difference = seconds(obj.getStartDateTime - obj.tfa1.getStartDateTime);
            startIndices = round(startIndices_temp * sampling_freq_ratio - obj.samplingFrequency * time_difference);
            endIndices = round(endIndices_temp * sampling_freq_ratio - obj.samplingFrequency * time_difference);
        end

        function signalToPredict = getSignalToPredict(obj) % double vector
            signalToPredict = obj.combinedSignal;
        end
        function segmentDuration = getSegmentDuration(obj) % [s]
            segmentDuration = obj.tfa1.slowTimePhase.segmentDuration;
        end

    end
end

