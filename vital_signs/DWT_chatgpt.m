% ---------------------------
% Przykład wizualizacji DWT
% ---------------------------

% 1. Sygnał przykładowy
fs = 1000;                         % częstotliwość próbkowania
t = 0:1/fs:1;
x = sin(2*pi*50*t) + sin(2*pi*10*t) + 0.5*randn(size(t));   % dwa tony + szum

% 2. DWT - 4 poziomy, fala Daubechies db5
wname = 'db5';
[c,l] = wavedec(x, 4, wname);

% 3. Odczyt współczynników z wektora c
A4 = appcoef(c,l,wname,4);      % aproksymacja poziomu 4
D4 = detcoef(c,l,4);            % detale poziomu 4
D3 = detcoef(c,l,3);
D2 = detcoef(c,l,2);
D1 = detcoef(c,l,1);

% 4. Wykresy
figure;
subplot(6,1,1)
plot(x); title('Sygnał wejściowy')

subplot(6,1,2)
plot(A4); title('A4 – aproksymacja poziomu 4 (bardzo niskie częstotliwości)')

subplot(6,1,3)
plot(D4); title('D4 – detale poziomu 4')

subplot(6,1,4)
plot(D3); title('D3 – detale poziomu 3')

subplot(6,1,5)
plot(D2); title('D2 – detale poziomu 2')

subplot(6,1,6)
plot(D1); title('D1 – detale poziomu 1 (wysokie częstotliwości)')

sgtitle('4-poziomowa dyskretna transformata falkowa (db5)')
