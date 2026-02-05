classdef SignalLoadingConfig
    %SIGNALLOADINGCONFIG This class exists only for the purpose of passing
    %struct with these variables as one argument to saveJson function
    
    properties
        lengthSeconds
        offsetSeconds
        filename
    end
    
    methods
        function obj = SignalLoadingConfig(lengthSeconds,offsetSeconds,filename)
            %SIGNALLOADINGCONFIG Construct an instance of this class
            obj.lengthSeconds = lengthSeconds;
            obj.offsetSeconds = offsetSeconds;
            obj.filename = filename;
        end

    end
end

