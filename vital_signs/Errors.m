classdef Errors
    %ERRORS A class for wrapping errors
    
    properties
        errors_memory_RMSE
        errors_memory_MAE
        errors_nomemory_RMSE
        errors_nomemory_MAE
    end
    
    methods
        function obj = Errors(errors_memory_RMSE,errors_memory_MAE, errors_nomemory_RMSE, errors_nomemory_MAE)
            %ERRORS Construct an instance of this class
            %   
            obj.errors_memory_RMSE = errors_memory_RMSE;
            obj.errors_memory_MAE = errors_memory_MAE;
            obj.errors_nomemory_RMSE = errors_nomemory_RMSE;
            obj.errors_nomemory_MAE = errors_nomemory_MAE;
        end
        

    end
end

