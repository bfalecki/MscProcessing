function [signal_comp] = subtractLinearComponent(signal)
%SUBTRACTLINEARCOMPONENT This function substracts linear component rom the
%signal

% example
% signal= [1 3 2 4 3 5 4 6 5 7 6 8].';

% COMPLEX WAY
% % % % signal_unit_diff = mean(diff(signal));
% % % % compensate_lags = repmat((0:size(signal,1)-1).',1, size(signal,2));
% % % % compensate_values = compensate_lags .* signal_unit_diff;
% % % % signal_comp = signal - compensate_values;

% SIMPLE WAY, SAME RESULT:
signal_comp = cumsum([signal(1); (diff(signal)-mean(diff(signal)))].');

end

