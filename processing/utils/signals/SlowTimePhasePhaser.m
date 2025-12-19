classdef SlowTimePhasePhaser < SlowTimePhase & SlowTimeSignalPhaserAny
    %SLOWTIMEPHASEPHASER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties

    end
    
    methods
        function obj = SlowTimePhasePhaser()
            %SLOWTIMEPHASEPHASER Construct an instance of this class
            obj.signalInfo.device = "phaser";
        end
        function initialize(obj, varargin)
            initialize@SlowTimeSignalPhaserAny(obj, varargin{:});
        end

        function initializePhaserRelated(obj,varargin)
            % initialize all things exclusively related to phaser
            initializePhaserRelated@SlowTimeSignalPhaserAny(obj, varargin{:});
        end
        

    end
end

