function [windowTimeCenters, peakVals, peakShifts, valleyVals, valleyShifts, time_ax] =...
    slidingWindowCorr(signal1,signal2,fs, windowWidth, windowStep, maxAllowableShift)
%SLIDINGWINDOWCORR 
% This function correlates signal1 with signal2 (fs [Hz]-sampled) segment-by-segment using
% window with windowWidth [s] sliding with step windowStep [s]
% maxAllowableShift [s] represents maximum allowable xcorr peak position
% relative to 0. If the peak is not the maximum value in
% [-maxAllowableShift, maxAllowableShift] bounds, the correlation peak is
% considered as not found, resulting in peakVals and peakShifts being NaN
% valleys state for negative correlation peaks
% shift is understood as a delay of signal1 with respect to signal2


% both signals must be the same size and time-synchronized 


% % example
% signal1 = [1 2 3 4 3 2 1 0 -1 -2 -3 -4 -3 -2 -1 0];
% signal1 = repmat(signal1, 1, 4);
% signal2 = circshift(signal1,2);
% fs = 10;
% windowWidth = 2;
% windowStep = windowWidth/2;
% maxAllowableShift = 0.5;

[~,max_size_idx] = max(size(signal1));
if(max_size_idx == 1)
    signal1 = signal1.';
end

[~,max_size_idx] = max(size(signal2));
if(max_size_idx == 1)
    signal2 = signal2.';
end


signalLen = length(signal1) / fs;
windowTimeCenters = windowWidth/2 : windowStep : signalLen - windowWidth/2;

% allocation
peakVals = zeros(size(windowTimeCenters));
peakShifts = zeros(size(windowTimeCenters));
valleyVals = zeros(size(windowTimeCenters));
valleyShifts = zeros(size(windowTimeCenters));

margin = 1.5;
window = get_gauss_win(windowWidth, fs, margin);

time_ax = (0:length(signal1)-1) / fs;
windowDuration = (length(window)-1) / fs;
window_time_ax = ((0:length(window)-1) / fs ) - windowDuration/2;

for k = 1:length(windowTimeCenters)
    % przyciac oba sygnaly odpowiednio, pomnozyc przez window i skorelowac

    % sygnał 1. ma być o rozmiarze okna
    time_start = windowTimeCenters(k) - windowDuration/2;
    time_end = windowTimeCenters(k) + windowDuration/2;

    time_ax_cut_indices = time_ax >= time_start & time_ax <= time_end;
    sig1cut = signal1(time_ax_cut_indices);
    sig2cut = signal2(time_ax_cut_indices);

    window_cut = window;

    % cut window if necessary
    if(time_ax_cut_indices(1) == 1)
        window_cut = window_cut(length(window) - length(sig1cut)+1:end);
    elseif(time_ax_cut_indices(end) == 1)
        window_cut = window_cut(1:end-(length(window) - length(sig1cut)));
    else
        if(length(sig1cut) < length(window_cut))
            window_cut = window_cut(1:end - (length(window_cut) - length(sig1cut)));
        end
        if(length(sig1cut) > length(window_cut))
            sig1cut = sig1cut(1:end - (length(sig1cut)- length(window_cut)));
            sig2cut = sig2cut(1:end - (length(sig1cut)- length(window_cut)));
        end
    end
    maxlag = ceil(maxAllowableShift*fs);

    % if(length(sig1cut) ~= length(window_cut))
    %     warning("length(sig1cut) ~= length(window_cut)")
    % end
    % 
    % if(length(sig1cut) ~= length(sig2cut))
    %     warning("length(sig1cut) ~= length(sig2cut)")
    % end

    [c,lags] = xcorr(sig1cut.*(window_cut.'),sig2cut,maxlag);

    

    [maxc, max_idx] = max(c);
    [minc, min_idx] = min(c); % for negative correlation
    maxc_lag = lags(max_idx);
    minc_lag = lags(min_idx);

    % we want only maxima
    if(max_idx == 1 || max_idx == length(lags))
        peakVals(k) = nan;
        peakShifts(k) = nan;
    else
        peakVals(k) = maxc;
        peakShifts(k) = -maxc_lag/fs;
    end

    if(min_idx == 1 || min_idx == length(lags))
        valleyVals(k) = nan;
        valleyShifts(k) = nan;
    else
        valleyVals(k) = minc;
        valleyShifts(k) = -minc_lag/fs;
    end

end


end

