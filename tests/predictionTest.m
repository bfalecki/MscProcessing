% Testing autoregressive prediction
x = [1 2 3 4 5 6 7 6 5 4 3 2 3 4 5 6 7 8 7 6 5 4 3 2 ].';


mean_val = mean(x);
x = x - mean_val;
order = 10;
A = aryule(x, order);



nSamplesToPredic = 10;
x_filled = [x; zeros(nSamplesToPredic,1)];

for predictedSampleIdx = length(x)+1:length(x)+nSamplesToPredic
    past = x_filled(predictedSampleIdx-1:-1:predictedSampleIdx-order);   % [x(k-1), x(k-2), ..., x(k-p)]
    x_filled(predictedSampleIdx) = -A(2:end) * past;        % x(k) = -sum_{i=1..p} a_i * x(k-i)
end

x = x+mean_val;
x_filled = x_filled + mean_val;

figure(1)
plot(x_filled, '*')
hold on
plot(x, "o")
hold off