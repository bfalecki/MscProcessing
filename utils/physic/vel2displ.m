function [displacement] = vel2displ(velocity, prf)
%VEL2DISPL transform velocity (m/s) to displacement (m)

% example
% prf = 1;
% velocity = [1 1 2 2];


displacement = cumsum(velocity) / prf;

end

