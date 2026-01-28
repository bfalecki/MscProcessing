function [applied, window] = applyGaussWindow(data,width)
%APPLYWINDOW Summary of this function goes here
%   Detailed explanation goes here

% width: 1 - FWHM equals full dimension
%        0.5 - FWHM equals half of the dimension
% data - can be matrix

arguments
    data 
    width = 0.5
end


window = gausswin(size(data,1), 1/(width/(2.354/2)));
applied = data .* window;

end

