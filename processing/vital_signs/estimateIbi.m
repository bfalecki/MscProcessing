function [ibiSeconds_pos] = estimateIbi(signal,fs,opts)
%ESTIMATEIBI This function estimates inter-beat interval

arguments
    signal % containing positive and negative heartbeat peaks, fs [Hz] sampled
    fs
    opts.MinPeakHeight = 1;
    % opts.doublePeaks = 0; % if we want to perform abs(signal) before peak finding

     % Support for phaser segments
    opts.StartSamples = [];
    opts.EndSamples = [];
    opts.EroseSize = 0;
end

if(~isempty(opts.StartSamples))
    segments_idxes = get_segments_idxes(opts.StartSamples,opts.EndSamples, length(signal));
    segments_idxes = ~ side_by_side_vector_erose(~segments_idxes,opts.EroseSize);
    segments_idxes = reshape(segments_idxes, size(signal));
    signal(~segments_idxes ) = nan;
end

[pks_pos, locs_pos] = findpeaks(signal, "MinPeakHeight",opts.MinPeakHeight);
ibiSeconds_pos = diff(locs_pos)/fs;
[pks_neg, locs_neg] = findpeaks(-signal, "MinPeakHeight",opts.MinPeakHeight);
ibiSeconds_neg = diff(locs_neg)/fs;


figure(1)
plot(signal, 'k')
hold on
plot([1 length(signal)], opts.MinPeakHeight, 'g--')
plot(locs_pos, pks_pos, 'go')
plot(locs_neg, pks_neg, 'ro')
hold off

% ibiSeconds_pos(ibiSeconds_pos > 2) = nan; % reject too high
% ibiSeconds_neg(ibiSeconds_neg > 2) = nan;

ibiSeconds_pos(ibiSeconds_pos < 0.2) = nan; % reject too low
ibiSeconds_neg(ibiSeconds_neg < 0.2) = nan;

% remove jumps over breaks
IBI_pos_reject_pos = findIbiPositionsOverBreaks(locs_pos, opts.StartSamples);
IBI_pos_reject_neg = findIbiPositionsOverBreaks(locs_neg, opts.StartSamples);
ibiSeconds_pos(IBI_pos_reject_pos) = nan;
ibiSeconds_neg(IBI_pos_reject_neg) = nan;


figure(2)
plot(locs_pos(2:end), ibiSeconds_pos, "Color",'g', 'Marker',"*")
hold on
plot(locs_neg(2:end), ibiSeconds_neg, "Color",'r', 'Marker',"*")
hold off
title("IBI [s]")

figure(4)
hr =  1./ibiSeconds_pos*60;
plot(locs_pos(2:end),hr, "k*")
title("HR [BPM]")

end

function IBI_pos_reject = findIbiPositionsOverBreaks(locs, startSamples)

    IBI_pos_reject = [];
    for k = 1:length(startSamples)
        % find first locs position after break
        distances =  locs - startSamples(k);
        distances(distances <= 0) = nan; % require positive

        [min_distance,loc_pos_after_break] = min(distances);
        
        % IBI position is locs position - 1
        if(~isnan(min_distance))
            IBI_pos_reject(end+1) = loc_pos_after_break - 1;
        end

    end
    IBI_pos_reject(IBI_pos_reject == 0) = [];
end
