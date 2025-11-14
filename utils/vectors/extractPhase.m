function [phase] = extractPhase(slow_time)
%EXTRACT_PHASE Summary of this function goes here
%   Detailed explanation goes here

phase = unwrap(angle(slow_time));

end

