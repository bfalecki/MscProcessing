classdef SignalInfo
    %SIGNALINFO This is a class representing signal / recording informations
    
    properties
        PRF % [Hz], what is the pulse repetition rate
        timeStart % datetime UTC, timestamp of the first sample
        device % "phaser" / "demorad24" / "demorad122" / "simulation"
        carrierFrequency % [Hz], carrier frequency of the radio signal
        bandWidth % [Hz], bandwidth of the radio signal
        samplingFrequency % sampling frequency of the ADC conferter
        frameStartTimes % [s], vector, when segments start, from the beggining of the file - only in case of phaser
        postRxTimes % [s], vector, when segment receptions completed, from the beggining of the file - only in case of phaser
    end
    
    methods
        function obj = SignalInfo(opts)
            %SIGNALINFO Construct an instance of this class
            arguments
                opts.PRF;
                opts.timeStart = datetime([1 1 1 0 0 0]);
                opts.device = [];
                opts.carrierFrequency;
                opts.bandWidth = [];
                opts.samplingFrequency = [];
                opts.frameStartTimes = []
                opts.postRxTimes = []
            end
            obj.PRF = opts.PRF;
            obj.timeStart = opts.timeStart;
            obj.device = opts.device;
            obj.carrierFrequency = opts.carrierFrequency;
            obj.bandWidth =  opts.bandWidth;
            obj.samplingFrequency = opts.samplingFrequency;
            obj.frameStartTimes = opts.frameStartTimes;
            obj.postRxTimes = opts.postRxTimes;
        end

    end
end

