classdef RawData
    %RAWDATA Class representing raw data
    
    properties
        data % raw data in a form of matrix, 1st dim = fast time, 2nd dim = slow time
        signalInfo % instance of SignalInfo
    end
    
    methods
        function obj = RawData(data, signalInfo)
            %RAWDATA Construct an instance of this class
            obj.data = data;
            obj.signalInfo = signalInfo;
        end
        
    end
end

