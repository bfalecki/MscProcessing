function [sigAdj] = modulateSampling(signal, timeAxis, shifts, shiftCenters, inversionWeigths)
% This function modulates the shift in the sampling of the signal (with time axis timeAxis [s])
% with respect to shifts [s] with centers shiftCenters [s]

% inversionWeigths change signs of signal segments before interpolation

% function connected to the results of selectBestSamplingShifts.m

% % example
% signal = [1 2 3 4 3 2 1 0 -1 -2 -3 -4 -3 -2 -1 0];
% signal = repmat(signal, 1, 4);
% fs = 10;
% timeAxis = (0:length(signal)-1) / fs;
% shifts = [ 0 0.5 0 -0.5 0];
% shiftCenters = [1     2     3     4     5];
% inversionWeigths = [1 1 -1 -1 -1];


optimal_delays = interp1(shiftCenters, shifts, timeAxis, 'linear');
inversionsExpanded = interp1(shiftCenters, inversionWeigths, timeAxis, 'nearest');

% nan replacement with nearest values
optimal_delays = fillmissing(optimal_delays, 'nearest');
inversionsExpanded = fillmissing(inversionsExpanded, 'nearest');

inversionsExpanded = reshape(inversionsExpanded, size(signal));

signal = signal.*inversionsExpanded;

optimal_sampling = optimal_delays + timeAxis;
sigAdj = interp1(timeAxis, signal,optimal_sampling,"spline");
sigAdj = reshape(sigAdj, size(signal));
end

