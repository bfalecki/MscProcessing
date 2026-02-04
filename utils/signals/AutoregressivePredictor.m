classdef AutoregressivePredictor < handle
    %AUTOREGRESSIVEPREDICTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % input
        predictable % must be Predictable
        ErosePartLeft
        ErosePartRight
        PartConsidered
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
        
        function predicted = predict(obj,predictable)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            obj.predictable = predictable;

        end
    end
end

