classdef  (Abstract) SlowTimeSignalAny < handle
    %SLOWTIMESIGNALANY kind of abstract class as a base
    
    properties
        rangeCellNumber % natural scalar (can be 2dim vector), from which range cell the signal originates, informative
        desiredRangeCellMeters % [m] scalar (can be 2dim vector), from which range cell in meters the signal originates, informative
        actualRangeCellsMeters % [m], (scalar or N dim vector) which range cells are actually accessed
        resamplingWasApplied % 1/0, if band reducing was applied in slow time, informative
        phaseDiscontinuitiesRemoved % 1/0, if phase discontinuities were removed using filter_phase_jumps function
        signalInfo % instance of SignalInfo class
    end
    
    methods
        function obj = SlowTimeSignalAny()
            %SLOWTIMESIGNALANY Construct an instance of this class
        end
        
        function initialize(obj,opts)
            %   Set the values
            arguments
                obj
                opts.rangeCellNumber = [];
                opts.desiredRangeCellMeters = [];
                opts.actualRangeCellsMeters = [];
                opts.signalInfo = obj.signalInfo;
                opts.resamplingWasApplied = 0;
                opts.phaseDiscontinuitiesRemoved = 0;
            end
            obj.rangeCellNumber = opts.rangeCellNumber;
            obj.desiredRangeCellMeters =opts.desiredRangeCellMeters;
            obj.actualRangeCellsMeters = opts.actualRangeCellsMeters;
            obj.signalInfo = opts.signalInfo;
            obj.resamplingWasApplied = opts.resamplingWasApplied;
            obj.phaseDiscontinuitiesRemoved = opts.phaseDiscontinuitiesRemoved;
        end
    end
end

