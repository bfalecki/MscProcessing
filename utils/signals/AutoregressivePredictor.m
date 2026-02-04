classdef AutoregressivePredictor < handle
    %AUTOREGRESSIVEPREDICTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % input
        predictable % must be Predictable
        ErosePartLeft
        ErosePartRight
        PartConsidered

        % results
        predictedIdxes
        predicted
    end
    
    methods
        function obj = AutoregressivePredictor(opts)
            %AUTOREGRESSIVEPREDICTOR Construct an instance of this class
            arguments
                opts.ErosePartLeft = 0 % left erose part of segment
                opts.ErosePartRight = 0 % right erose part of segment
                opts.PartConsidered = 1 % remaining part of segment which is taken into account during prediction
            end
            obj.ErosePartLeft =  opts.ErosePartRight;
            obj.ErosePartRight =  opts.ErosePartRight;
            obj.PartConsidered =  opts.PartConsidered;
        end

        
        function predict(obj,predictable)
            %This function performs prediction
            arguments
                obj
                predictable Predictable
            end
            obj.predictable = predictable;
            [start_samples ,end_samples]= predictable.getSegmentsStartsEnds();
            segments_idxes = get_segments_idxes(start_samples,end_samples, length(predictable.getSignalToPredict));

            eroseLengthLeft = predictable.getSegmentDuration * ...
                predictable.getSamplingFrequency * ...
                obj.ErosePartLeft /2;
            eroseLengthLeft = round(eroseLengthLeft);

            eroseLengthRight = predictable.getSegmentDuration * ...
                predictable.getSamplingFrequency * ...
                obj.ErosePartRight /2;
            eroseLengthRight = round(eroseLengthRight);

            segments_idxes_er = side_by_side_vector_erose(segments_idxes, eroseLengthLeft, "left");
            segments_idxes_er = side_by_side_vector_erose(segments_idxes_er, eroseLengthRight, "right");
            obj.predictedIdxes = ~segments_idxes_er;

            obj.predicted = fill_gaps_ar_wrapped(predictable.getSignalToPredict ,...
                predictable.getSamplingFrequency,segments_idxes_er ,predictable.getSegmentDuration, ...
                "PartConsidered",obj.PartConsidered,"edge_ignore_length",0);
        end
    end
end

