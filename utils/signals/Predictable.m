classdef (Abstract) Predictable < handle
    % This abstract class is an interface for autoregressive prediction
    
    properties
        % inputs
        ErosePartLeft
        ErosePartRight
        PartConsidered


        % output
        predicted
        predictedIdxes % binary idxes, ones: where prediction filled breaks, zeros: samples seen to predictor
        segmentsIdxes % binary idxes, zeros exactly in breaks
        rank % number of considered history samples for each segment

        % time frequency analysis output
        furtherAnalysisOutput
    end
    
    methods

        function fixDiscontinuities(obj)
            obj.predicted = compl_diff(diff(obj.predicted));
            obj.predicted = filter_noise_peaks(obj.predicted, "Display",0);
            obj.predicted = cumsum(obj.predicted);
            obj.predicted = highpass(obj.predicted, 1/obj.getSamplingFrequency);

        end

        function predict(obj,opts)
            %This function performs prediction
            arguments
                obj
                opts.ErosePartLeft = 0 % left erose part of segment
                opts.ErosePartRight = 0 % right erose part of segment
                opts.PartConsidered = 1 % part of segment which is taken into account during prediction
            end
            obj.ErosePartLeft =  opts.ErosePartLeft;
            obj.ErosePartRight =  opts.ErosePartRight;
            obj.PartConsidered =  opts.PartConsidered;
            [start_samples ,end_samples]= obj.getSegmentsStartsEnds();
            obj.segmentsIdxes = get_segments_idxes(start_samples,end_samples, length(obj.getSignalToPredict));

            eroseLengthLeft = obj.getSegmentDuration * ...
                obj.getSamplingFrequency * ...
                obj.ErosePartLeft;
            eroseLengthLeft = round(eroseLengthLeft);

            eroseLengthRight = obj.getSegmentDuration * ...
                obj.getSamplingFrequency * ...
                obj.ErosePartRight;
            eroseLengthRight = round(eroseLengthRight);

            if(eroseLengthLeft < 0)
                segments_idxes_er = ~side_by_side_vector_erose([~obj.segmentsIdxes(:).' 1],-eroseLengthLeft, "right");
                segments_idxes_er = segments_idxes_er(1:end-1);
            else
                segments_idxes_er = side_by_side_vector_erose(obj.segmentsIdxes, eroseLengthLeft, "left");
            end

            % erosion can be negative
            if(eroseLengthRight < 0)
                segments_idxes_er = ~side_by_side_vector_erose([1 ~obj.segmentsIdxes(:).'],-eroseLengthRight, "left");
                segments_idxes_er = segments_idxes_er(2:end);
            else
                segments_idxes_er = side_by_side_vector_erose(segments_idxes_er, eroseLengthRight, "right");
            end
            
            
            obj.predictedIdxes = ~segments_idxes_er;

            [obj.predicted, obj.rank] = fill_gaps_ar_wrapped(obj.getSignalToPredict ,...
                obj.getSamplingFrequency,segments_idxes_er ,obj.getSegmentDuration, ...
                "PartConsidered",obj.PartConsidered,"edge_ignore_length",0);
        end
        function predicted = getPredicted(obj)
            predicted = obj.predicted;
        end
        function predictedIdxes = getPredictedIdxes(obj)
            predictedIdxes = obj.predictedIdxes;
        end
        function plotPredictionResult(obj, opts)
            arguments
                obj
                opts.PlotOriginal = 1 % plot full signal to predict
                opts.PlotBounds = 0 % mark prediction bounds
                opts.PlotAvailable = 1 % plot available signal with breaks cut exactly
                opts.PlotSeen = obj.PartConsidered ~= 1 % plot signal seen to predictor / training samples
                opts.PlotConsidered = 1 % plot signal part used by predictor / p last samples
            end
            time_ax = (0:(length(obj.getPredicted)-1)) /  obj.getSamplingFrequency();
            legendEntries = strings([]);
            if(opts.PlotOriginal)
                plot(time_ax, obj.getSignalToPredict, Color='r',LineStyle='-',LineWidth=1.5)
                legendEntries(end+1) = "Original";
                hold on
            end
            if(opts.PlotAvailable)
                signalAvailable = obj.getSignalToPredict;
                signalAvailable(~obj.segmentsIdxes) = nan;
                plot(time_ax, signalAvailable, Color='k',LineStyle='-',LineWidth=1.5)
                legendEntries(end+1) = "Available";
                hold on
            end
            if(opts.PlotSeen)
                signalSeen = obj.getSignalToPredict;
                signalSeen(obj.predictedIdxes) = nan;
                plot(time_ax, signalSeen, Color='b',LineStyle='-', LineWidth=1.5)
                legendEntries(end+1) = "Seen";
                hold on
            end
            if(opts.PlotConsidered)
                signalConsidered = obj.getSignalToPredict;
                seenIdxes = ~obj.predictedIdxes;
                notConsideredIdxes = side_by_side_vector_erose(seenIdxes,obj.rank, "right");
                consideredIdxes = xor(seenIdxes, notConsideredIdxes);
                signalConsidered(~consideredIdxes) = nan;
                plot(time_ax, signalConsidered, Color='g',LineStyle='-', LineWidth=1.5)
                legendEntries(end+1) = "Considered";
                hold on
            end


            signalPredictedExclusive = obj.getPredicted;
            signalPredictedExclusive(~obj.predictedIdxes) = nan;
            plot(time_ax, signalPredictedExclusive, Color='k',LineStyle='-.')
            legendEntries(end+1) = "Predicted";
            hold on

            if(opts.PlotBounds)
                [startIndices, endIndices] = obj.getPredictionStartEnds;
                signalNonPredicted =  obj.getSignalToPredict;
                plot(time_ax(startIndices), signalNonPredicted(startIndices), 'r*')
                plot(time_ax(endIndices), signalNonPredicted(endIndices), 'b*')
                legendEntries = [legendEntries "Pred. Starts" "Pred. Ends"];
                hold on
            end

            hold off
            legend(legendEntries)
        end
        function [startIndices, endIndices]  = getPredictionStartEnds(obj)
            [startIndices, endIndices] = logical2segmentIdxes(obj.getPredictedIdxes);
        end
        function setTfAnalysisOutput(obj,outputType)
            % set output for time-freq analysis
            arguments
                obj 
                outputType % "default" (signal before prediction) / "predicted" (signal after prediction)
            end
            if(strcmp(outputType, "nonpredicted"))
                obj.furtherAnalysisOutput = "nonpredicted";
            elseif(strcmp(outputType, "predicted"))
                obj.furtherAnalysisOutput = "predicted";
            else
                error("Invalid type: " + outputType)
            end
        end

        function signal = getSignal(obj)% get signal depending on furtherAnalysisOutput
            if(strcmp(obj.furtherAnalysisOutput,"nonpredicted"))
                signal = obj.getSignalToPredict;
            elseif(strcmp(obj.furtherAnalysisOutput,"predicted"))
                signal = obj.getPredicted;
            end
        end

    end
    methods (Abstract)
        [startIndices, endIndices] = getSegmentsStartsEnds(obj) % get segment start-end indices
        signalToPredict = getSignalToPredict(obj) % double vector
        segmentDuration = getSegmentDuration(obj) % [s]
        samplingFrequency = getSamplingFrequency(obj) % Hz
    end
end

