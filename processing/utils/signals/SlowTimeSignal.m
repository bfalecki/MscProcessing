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

        function selectSingleCell(obj, rangeCellMeters)
            % see documentation for selectSingleCell@SlowTimeSignalAny
            relativeIdx = selectSingleCell@SlowTimeSignalAny(obj,rangeCellMeters);
            obj.signal = obj.signal(relativeIdx, :);
            
        end

        function plotSignal(obj)
            % display phase signal
            t_ax = obj.getTimeAx();
            if(~isscalar(obj.actualRangeCellsMeters))
                plot(t_ax,real(obj.signal).', LineWidth=2);
                ax = gca;
                ax.ColorOrderIndex = 1;
                hold on
                plot(t_ax,imag(obj.signal).', LineWidth=1);
                hold off
                legend(string(obj.actualRangeCellsMeters) + " m")
            else
                plot(t_ax,real(obj.signal));
                hold on
                plot(t_ax,imag(obj.signal));
                hold off
                legend("Real Part", "Imag. Part")
            end
            xlabel("Time [s]")
            ylabel("Amplitude")
        end
        function t_ax = getTimeAx(obj)
            t_ax = 0: 1/obj.signalInfo.PRF : (size(obj.signal,2)-1) / obj.signalInfo.PRF;
        end
    end
end

