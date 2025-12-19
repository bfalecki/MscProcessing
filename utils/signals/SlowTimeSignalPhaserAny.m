classdef (Abstract) SlowTimeSignalPhaserAny < SlowTimeSignalAny
    %SLOWTIMESIGNALPHASERANY kind of abstract class for slow time signal
    %representation from phaser
    
    properties
        segmentStartIndices % vector of segment start indices, for example [1 201 401]
        segmentEndIndices % vector of segment end indices, for example [150 350 550]
        segmentDuration % what is the length of a signle frame [s]
        
    end
    
    methods
        function initialize(obj, varargin)
            % 1. wywołanie implementacji bazowej
            initialize@SlowTimeSignalAny(obj, varargin{:});

            % 2. nadpisanie / ustawienie na stałe
            obj.signalInfo.device = "phaser";
        end

        function initializePhaserRelated(obj,opts)
            % initialize all things exclusively related to phaser
            arguments
                obj
                opts.segmentStartIndices
                opts.segmentEndIndices
                opts.segmentDuration
            end
            
            obj.segmentStartIndices = opts.segmentStartIndices;
            obj.segmentEndIndices = opts.segmentEndIndices;
            obj.segmentDuration = opts.segmentDuration;

        end
    end
end

