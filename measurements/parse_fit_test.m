% Import biblioteki Pythona (fitparse musi być zainstalowany w środowisku Python)
py.importlib.import_module('fitparse');

fitfile = py.fitparse.FitFile('test\eu286f270e7f73e7e7d4_2025-09-29_bieg.fit');

% NIE DZIALA
% records_gen = fitfile.get_messages('record');
% it = records_gen.iterator();
% while it.hasNext()
%     rec = it.next();
%     fields = rec.get_data();
%     disp(fields);
% end


% % NIE DZIALA
% % py.fitparse.FitFile('trening.fit') zwraca fitfile
% records_gen = fitfile.get_messages('record');
% % Konwertujemy generator na listę Pythona
% records_list = py.list(records_gen);
% % Teraz można po niej iterować w MATLAB-ie
% for k = 1:length(records_list)
%     rec = records_list{k};           % pobieramy rekord
%     fields = rec.get_data();         % słownik pól
%     disp(fields);
% end


%NIE DZIALA
% % Iteracja po rekordach
% records = fitfile.get_messages('record');
% for rec = records
%     fields = rec.get_data();
%     disp(fields);
% end


% Pobierz wszystkie rekordy
records_list = py.list(fitfile.get_messages('record'));

time = datetime(); % empty datetime vector
time(1) = [];
hr   = [];
speed = [];

for k = 1:length(records_list)
    rec = records_list{k};
    
    % rec.fields jest listą pól, każde pole ma name i value
    fields = py.list(rec.fields);
    
    % Tymczasowe zmienne
    t_time = [];
    t_hr   = [];
    t_speed= [];
    
    for f = 1:length(fields)
        field = fields{f};
        fname = char(field.name);       % nazwa pola
        
        switch fname
            case 'timestamp'
                t_time = field.value;
            case 'heart_rate'
                t_hr = field.value;
            case 'speed'
                t_speed = field.value;
        end
    end
    
    % Dodaj do tabeli
    if ~isempty(t_time)
        time(end+1)  = t_time;
        hr(end+1)    = t_hr;
        speed(end+1) = t_speed;
    end
end



% Wykres
figure;
subplot(2,1,1);
plot(time, hr);
ylabel('[bpm]');
title('Heart rate');

subplot(2,1,2);
plot(time, speed);
ylabel('Velocity [m/s]');
xlabel('Czas');
title('Przebieg prędkości');
