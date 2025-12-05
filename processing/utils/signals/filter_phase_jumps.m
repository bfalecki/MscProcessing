function IQSignal_comp = filter_phase_jumps(IQSignal, unwrapped_phase_diff,filtered_phase_diff)
%FILTER_PHASE_JUMPS Summary of this function goes here
%   Detailed explanation goes here
    phase_compensation = cumsum(filtered_phase_diff) - cumsum(unwrapped_phase_diff);
    IQSignal_comp = IQSignal .* exp(1j*phase_compensation);
end

