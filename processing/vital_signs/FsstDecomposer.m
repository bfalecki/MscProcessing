classdef FsstDecomposer < handle
    %FSSTDECOMPOSER
    % This class represents Fourier Synchrosqueezing Transform Decomposer
    % as a method for decomposing heartbeat and breat signals
    
    properties
        velocityMax % [m/s], maximum velocity of the distribution
        windowWidth % [s], Fourier Synchrosqueezing Transform window width
        nTfridges % 1,2,3..., how many time-frequency ridges to filter-out
        filterWidth % [m/s], how much distribution to cut out in the frequency, following tfridges
        rmsEnvelopeWidth % [s], what is the window width for root-mean-square envelope calculation
    end
    
    methods
        function obj = fsstDecomposer(opts)
            %FSSTDECOMPOSER Construct an instance of this class
            %   here we can provide configuration of the class parameters
            arguments
                opts.velocityMax = 0.05;
                opts.windowWidth = 0.2;
                opts.nTfridges = 1;
                opts.filterWidth = 0.001;
                opts.rmsEnvelopeWidth = 0.2;
            end

            obj.velocityMax = opts.velocityMax; 
            obj.windowWidth =   opts.windowWidth;
            obj.nTfridges = opts.nTfridges;
            obj.filterWidth =   opts.filterWidth;
            obj.rmsEnvelopeWidth =   opts.rmsEnvelopeWidth;
        end
        
        function outputArg = process(slowTimeSignal)
            % This method is called to process the data
            % input: slowTimeSignal - SlowTimeSignal instance


        end
    end
end

