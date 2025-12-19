classdef SlowTimeSignal < SlowTimeSignalAny
    %SLOWTIMESIGNAL
    
    properties
        signal % complex double vector, IQ raw signal from range-time map

    end
    
    methods
        function obj = SlowTimeSignal()
            %SLOWTIMESIGNAL Construct an instance of this class
        end

        function initialize(obj, varargin)
            initialize@SlowTimeSignalAny(obj, varargin{:});
        end

        function setSignal(obj,signal)
            obj.signal = signal;
        end
        
    end
end

