function signalAdjusted = adjustSampling(signal, currentFs, desiredFs, ...
    currentDatetimeStart, desiredDatetimeStart, method)
%ADJUSTSAMPLING Adjusts sampling of the signal using interp1
%
% signal - signal to adjust (vector)
% currentFs - current sampling frequency [Hz]
% desiredFs - desired sampling frequency [Hz]
% currentDatetimeStart - datetime of first sample in original signal
% desiredDatetimeStart - datetime of first sample in adjusted signal
% method - interpolation method for interp1 (e.g. 'linear', 'spline', 'pchip')

% % example
% signal = [1 2 3 2 1 0 -1 -2 -1 0 2 -1];
% currentFs = 1;
% desiredFs = 2.5;
% currentDatetimeStart = datetime([2026 1 1 0 0 0]);
% desiredDatetimeStart = datetime([2026 1 1 0 0 2]);
% method = "linear";



% implementation by ChatGPT

    % number of samples
    N = length(signal);

    % original time vector (seconds)
    t_current = (0:N-1)' / currentFs + ...
                seconds(currentDatetimeStart - desiredDatetimeStart);

    % duration of signal
    duration = (N-1) / currentFs;

    % desired time vector
    t_desired = (0 : 1/desiredFs : duration)';

    % interpolation
    signalAdjusted = interp1(t_current, signal, t_desired, method, 0);

    % close all
    % figure; plot(t_current,signal)
    % figure;plot(t_desired,signalAdjusted)

end
