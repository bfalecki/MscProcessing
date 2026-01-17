function IQSignal_comp = filter_phase_jumps(IQSignal, unwrapped_phase_diff,filtered_phase_diff)
%FILTER_PHASE_JUMPS This function applies the result of filter-noise-peaks
%function to compensate the related IQ signal.
    % IQSignal - IQ signal to be compensated (for removing phase discountinuities)
    % unwrapped_phase_diff - differentiated unwrapped phase, unfiltered
    % filtered_phase_diff - differentiatedunwrapped phase, peaks removed
    phase_compensation = cumsum(filtered_phase_diff) - cumsum(unwrapped_phase_diff);
    IQSignal_comp = IQSignal .* exp(1j*phase_compensation);
end

