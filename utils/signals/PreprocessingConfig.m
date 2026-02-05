classdef PreprocessingConfig
    %PREPROCESSINGCONFIG This class exists only for the purpose of passing
    %struct with these variables as one argument to saveJson function
    
    properties
        range_cell
        fast_time_data_start
        fast_time_data_end
        FastTimeWindow
        phaseUnwrappingMethod
        phaseDiscontCompParams
    end
    
    methods
        function obj = PreprocessingConfig(range_cell,fast_time_data_start,fast_time_data_end,FastTimeWindow,phaseUnwrappingMethod,phaseDiscontCompParams)
            %PREPROCESSINGCONFIG Construct an instance of this class
            obj.range_cell =range_cell ;
            obj.fast_time_data_start =fast_time_data_start ;
            obj.fast_time_data_end =fast_time_data_end ;
            obj.FastTimeWindow =FastTimeWindow ;
            obj.phaseUnwrappingMethod =phaseUnwrappingMethod ;
            obj.phaseDiscontCompParams =phaseDiscontCompParams ;
        end

    end
end

