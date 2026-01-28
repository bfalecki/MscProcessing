function [shifts,inversionWeigths] = selectBestSamplingShifts(peakVals, peakShifts, valleyVals, valleyShifts, considerNegative)
%SELECTBESTSAMPLINGSHIFTS This function selects best sampling shifts with
%given xcorr-related peaks and valleys values and positions
% for valley consideration, use considerNegative = 1;

% this function is related with output of slidingWindowCorr.m

% % example
% peakVals = [150 150 nan 150 150];
% valleyVals = [60 nan nan 170 nan];
% peakShifts = [ 0 -0.5 nan -0.5 0];
% valleyShifts = [-2 nan nan 3 nan];

if(considerNegative)
    [maxCorr, maxIdx]=max([peakVals; valleyVals],[], 1);
    max_idx_linear = maxIdx + (2*(0:length(maxIdx)-1));
    possibleShifts = [peakShifts;valleyShifts];
    
    selectedShifts = possibleShifts(max_idx_linear);
    shifts = fillmissing(selectedShifts,"linear");
    inversionWeigths = (maxIdx == 1)*2-1;
else
    shifts = fillmissing(peakShifts,"linear");
    inversionWeigths = ones(size(shifts));
end


end

