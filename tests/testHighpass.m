
fs = 1000; % Hz
f_sin = 250; % Hz
f_pass = 270; % Hz
N = 1000;
t = (0:N-1)/fs;
x = (t >= 0.5) .* sin(2*pi*f_sin*t);
y = highpass(x, f_pass/(fs/2),"ImpulseResponse",'fir');
figure(1); plot([x.', y.'])