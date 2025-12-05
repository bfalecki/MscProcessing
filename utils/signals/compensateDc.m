function [signalComp, best_middle] = compensateDc(signalIQ, opts)
%COMPENSATEDC this function makes DC compensation of the signal

arguments
    signalIQ 
    opts.method = 'mean' % 'mean' or 'minstd'
    opts.FindPoints = 20 % find grid size
end

if(isempty(opts.FindPoints))
    opts.FindPoints = 20;
end
if(isempty(opts.method))
    opts.method = 'mean';
end

middle = mean(signalIQ);

if(strcmp(opts.method, 'mean'))
    best_middle = middle;
elseif(strcmp(opts.method, 'minstd'))
    pts = 20;
    middles = linspace(middle - 2*middle, middle + 1*middle, pts);
    [middlesReal, middlesImag] = meshgrid(real(middles),imag(middles));
    middlesMesh = complex(middlesReal, middlesImag);
    
    middlesVect = reshape(middlesMesh, [size(middlesMesh,1)*size(middlesMesh,2) 1]);
    
    % we create a matrix
    compensated = reshape(signalIQ, [1, length(signalIQ)]) - middlesVect;
    
    % then we check std in second dim
    criterion_fun = std(abs(compensated),[],2);
    
    [~, best_middle_idx] = min(criterion_fun);
    best_middle = middlesVect(best_middle_idx);
end

signalComp = signalIQ - best_middle;
end

% % example
% slow_time_raw = slow_time(1:8000);
% [slow_time_compDC_mean, middle_mean] = compensateDc(slow_time_raw, "method",'mean');
% [slow_time_compDC_minstd,middle_minstd] = compensateDc(slow_time_raw, "method",'minstd');
% figure(12)
% plot(slow_time_raw, 'k')
% hold on
% plot(slow_time_compDC_mean, 'b')
% plot(slow_time_compDC_minstd, 'r')
% plot(0, 0, '*k')
% plot(-middle_mean, '*b')
% plot(-middle_minstd, '*r')
% hold off
% legend('not comp.','mean comp','minstd comp')
