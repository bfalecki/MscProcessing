classdef SlowTimePhase < SlowTimeSignalAny
    %SLOWTIMEPHASE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        phase % phase signal
    end
    
    methods
        function obj = SlowTimePhase()
            %SLOWTIMEPHASE Construct an instance of this class

        end
        
        function setPhase(obj,phase)
            %METHOD1 Summary of this method goes here
            obj.phase = phase;
        end

        function selectSingleCell(obj, rangeCellMeters)
            % see documentation for selectSingleCell@SlowTimeSignalAny
            relativeIdx = selectSingleCell@SlowTimeSignalAny(obj,rangeCellMeters);
            obj.phase = obj.phase(relativeIdx, :);
            
        end

        function plotPhase(obj)
            % display phase signal
            t_ax = obj.getTimeAx();
            plot(t_ax,obj.phase.');
            if(~isscalar(obj.actualRangeCellsMeters))
                legend(string(obj.actualRangeCellsMeters) + " m")
            end
            xlabel("Time [s]")
            ylabel("Unwrapped Phase [rad]")
        end

        function plotPhaseDiff(obj)
            % display phase diff signal
            t_ax = obj.getTimeAx();
            plot(t_ax(1:end-1),diff(obj.phase.')*obj.signalInfo.PRF);
            if(obj.resamplingWasApplied)
                warning("Missing amplitude correction due to resampling: obj.signalInfo.PRF / decimRank")
            end
            if(~isscalar(obj.actualRangeCellsMeters))
                legend(string(obj.actualRangeCellsMeters) + " m")
            end
            xlabel("Time [s]")
            ylabel("Unwrapped Phase Diff. [rad/s]")
        end

        function t_ax = getTimeAx(obj)
            t_ax = 0: 1/obj.signalInfo.PRF : (size(obj.phase,2)-1) / obj.signalInfo.PRF;
        end

    end
end

