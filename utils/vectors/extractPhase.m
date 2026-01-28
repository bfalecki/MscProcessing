function [phase] = extractPhase(IQSignal, method)
%EXTRACT_PHASE Summary of this function goes here
%   Detailed explanation goes here

% method = 'atan'; % "atan"  "dacm" "mdacm"


arguments
    IQSignal 
    method = "atan"
end

if(length(IQSignal) ~= size(IQSignal,1)) % fix transposition
    IQSignal = IQSignal.';
end

if(strcmp(method, "atan"))
    phase = unwrap(angle(IQSignal));
elseif(strcmp(method, "dacm")) % TO DO : OPTIMIZE AND VECTORIZE
    %%% Φ[n] = ∑k=2...n (I[k]{Q[k]−Q[k−1]}−{I[k]−I[k−1]}Q[k])/(I[k]^2+Q[k]^2)
    I = real(IQSignal);
    Q = imag(IQSignal);
    N = 2:length(IQSignal);
    differDACM = zeros(1,length(IQSignal));
    phase = zeros(1,length(IQSignal));
    
    for n = N
        differDACM(n) = (I(n)*(Q(n)-Q(n-1))  - (I(n)-I(n-1))*Q(n)) / (I(n)^2 + Q(n)^2); 
    end
    for n = N
        phase(n) = sum(differDACM(2:n)); 
    end
elseif(strcmp(method, "mdacm"))
    %%% phase extraction MDACM
    % Φ[n]=∑k=2...n  I[k−1]Q[k]−I[k]Q[k−1]
    differMDACM = zeros(1,length(IQSignal));
    phase = zeros(1,length(IQSignal));
    N = 2:length(IQSignal);
    I = real(IQSignal);
    Q = imag(IQSignal);
    
    ampl = sqrt(I.^2 + Q.^2);
    I = I ./ ampl;
    Q = Q ./ ampl;
    
    for n = N
        differMDACM(n) = (I(n-1)*Q(n) - I(n)*Q(n-1)); 
    end
    for n = N
        phase(n) = sum(differMDACM(2:n)); 
    end
end


end

