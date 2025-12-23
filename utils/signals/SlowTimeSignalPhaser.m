classdef SlowTimeSignalPhaser < SlowTimeSignal & SlowTimeSignalPhaserAny
    %SLOWTIMESIGNALPHASER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % segmentStartIndices % vector of segment start indices, for example [1 201 401]
        % segmentEndIndices % vector of segment end indices, for example [150 350 550]
        % segmentDuration % what is the length of a signle frame [s]
        % signal % IQ signal
    end
    
    methods
        function obj = SlowTimeSignalPhaser()
            %SLOWTIMESIGNALPHASER Construct an instance of this class
            obj.signalInfo.device = "phaser";
        end

        function initialize(obj, varargin)
            % 1. wywołanie implementacji bazowej
            initialize@SlowTimeSignalPhaserAny(obj, varargin{:});

            % 2. nadpisanie / ustawienie na stałe
            obj.signalInfo.device = "phaser";
        end

        % function initializePhaserRelated(obj,opts)
        %     % initialize all things exclusively related to phaser
        %     arguments
        %         obj
        %         % opts.segmentStartIndices
        %         % opts.segmentEndIndices
        %         % opts.segmentDuration
        %     end
        % 
        %     % obj.segmentStartIndices = opts.segmentStartIndices;
        %     % obj.segmentEndIndices = opts.segmentEndIndices;
        %     % obj.segmentDuration = opts.segmentDuration;
        % end

        % function setSignal(obj,signal)
        %     obj.signal = signal;
        % end
        
    end

end

