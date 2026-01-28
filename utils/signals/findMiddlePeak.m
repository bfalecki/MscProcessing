function [selected_peaks,selected_locs] = findMiddlePeak(matrix)
%FINDMIDDLEPEAK this function finds 3 maksima and chooses the middle one

% example
% matrix = [0,0,0; 1 2 3; 0,0,0; 100 200 300 ; 0.1 0.2 0.3; 0,0,0; 0.01, 0.02, 0.03; 0 0 0];

selected_peaks = zeros(1, size(matrix, 2));
selected_locs = zeros(1, size(matrix, 2));
for k = 1:size(matrix, 2)
    column = matrix(:,k);
    [~, locs] = findpeaks(column,"NPeaks",3,"SortStr","descend");
    if(isscalar(locs))
        selected_locs(k) = locs;
        selected_peaks(k) = column(selected_locs(k));
    elseif(length(locs) == 2)
        selected_locs(k) = min(locs);
        selected_peaks(k) = column(selected_locs(k));
    elseif(length(locs) == 3)
        selected_locs(k) = median(locs);
        selected_peaks(k) = column(selected_locs(k));
    else
        selected_locs(k) = nan;
        selected_peaks(k) = nan;
    end
end


end

