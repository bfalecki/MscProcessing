

function [signal_norm] = normalizeEnvelope(signal, windowWidth)
%NORMALIZEENVELOPE This function divides the signal by its envelope to
% suppress amplitude modulation related to data segmentation and
% respiratory movement

% normWindow = 0.5;
% signal= rc.combinedSignal;
% windowWidth = round(normWindow*rc.getSamplingFrequency);

envel = envelope(signal,windowWidth,'analytic');
envel = envel / rms(envel);
signal_norm = signal./envel;


figure(9991);
plot(signal)
hold on; 
plot(envel)
plot(signal_norm)
hold off
end

