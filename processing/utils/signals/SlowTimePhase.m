classdef SlowTimePhase < SlowTimeSignalAny
    %SLOWTIMEPHASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        phase
    end
    
    methods
        function obj = SlowTimePhase()
            %SLOWTIMEPHASE Construct an instance of this class

        end
        
        function setPhase(obj,phase)
            %METHOD1 Summary of this method goes here
            obj.phase = phase;
        end
    end
end

