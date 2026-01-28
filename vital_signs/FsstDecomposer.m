classdef FsstDecomposer < handle
    %FSSTDECOMPOSER
    % This class represents Fourier Synchrosqueezing Transform Decomposer
    % as a method for decomposing heartbeat and breat signals
    
    properties
        velocityMax % [m/s], maximum velocity of the distribution
        windowWidth % [s], Fourier Synchrosqueezing Transform window width
        nTfridges % 1,2,3..., how many time-frequency ridges to filter-out
        filterWidth % [m/s], how much distribution to cut out in the frequency, following tfridges
        rmsEnvelopeWidth % [s], what is the window width for root-mean-square envelope calculation
        velocityResolution % [m/s], Doppler velocity pixel size of the distribution
        rank % vertical synchrosqueezing rank

        S % computed STFT matrix
        SE % computed SSTFT matrix
        t_ax % time axis of S/SE
        v_ax % Doppler velocity axis of S/SE
        f_ax % Doppler frequency axis of S/SE
        breathIQ % IQ breath-part signal
        heartbeatIQ % IQ heartbeat-part signal
        heartbeatEnvelope % real heartbeat activity envelope
    end
    
    methods
        function obj = fsstDecomposer(opts)
            %FSSTDECOMPOSER Construct an instance of this class
            %   here we can provide configuration of the class parameters
            arguments
                opts.velocityMax = 0.05;
                opts.windowWidth = 0.2;
                opts.nTfridges = 1;
                opts.filterWidth = 0.001;
                opts.rmsEnvelopeWidth = 0.2;
                opts.velocityResolution = [];
                opts.rank = 1;
            end

            if(isempty(opts.velocityResolution))
                opts.velocityResolution = 2*opts.velocityMax/128;
            end

            obj.velocityMax = opts.velocityMax; 
            obj.windowWidth =   opts.windowWidth;
            obj.nTfridges = opts.nTfridges;
            obj.filterWidth =   opts.filterWidth;
            obj.rmsEnvelopeWidth = opts.rmsEnvelopeWidth;
            obj.velocityResolution = opts.velocityResolution;
            obj.rank = opts.rank;
        end

        function plotStft(obj)
            
            % plot STFT
            % only after process()
            max_val = max(db(obj.S),[], "all");
            clim_min = quantile(db(nonzeros(obj.S)),0.1,"all");
            clim_max = quantile(db(nonzeros(obj.S)),0.99,"all");
            clims = [clim_min clim_max] - max_val; % max_value is substracted
            % cmap = flip(gray);
            cmap = "jet";
            plot_surf(obj.S,obj.t_ax,obj.v_ax, 1,"", cmap, clims)
            xlabel("Time [s]"); ylabel("Doppler Velocity [Hz]");
            ylim([0  obj.velocityMax])
            c = colorbar;
            c.Label.String = 'Energy [dB]';
            title("Doppler Velocity STFT")
        end

        function plotSstft(obj)
            
            % plot STFT
            % only after process()
            max_val = max(db(obj.SE),[], "all");
            clim_min = quantile(db(nonzeros(obj.SE)),0.1,"all");
            clim_max = quantile(db(nonzeros(obj.SE)),0.99,"all");
            clims = [clim_min clim_max] - max_val; % max_value is substracted
            % cmap = flip(gray);
            cmap = "jet";
            plot_surf(obj.SE,obj.t_ax,obj.v_ax, 1,"", cmap, clims)
            xlabel("Time [s]"); ylabel("Doppler Velocity [Hz]");
            ylim([0  obj.velocityMax])
            c = colorbar;
            c.Label.String = 'Energy [dB]';
            title("Doppler Velocity SSTFT")
        end
        
        function process(obj,slowTimeSignal)
            % This method is called to process the data
            % input: slowTimeSignal - SlowTimeSignal instance

            % velocityMax -> fDopplerMax -> slowTimeSamplingFreq
            fc = slowTimeSignal.signalInfo.carrierFrequency;
            fDopplerMax = vel2fdoppler(obj.velocityMax,fc);
            newSlowTimeSamplingFreq = fDopplerMax * 2; % [-fDopplerMax/2  fDopplerMax/2] interval
            

            % perform decimation
            if(newSlowTimeSamplingFreq < slowTimeSignal.signalInfo.PRF)
                [signal,fs] = set_fs(slowTimeSignal.signal, ...
                    slowTimeSignal.signalInfo.PRF, ...
                    newSlowTimeSamplingFreq);
            else % or leave it like it is if PRF is too small
                signal = slowTimeSignal.signal;
                fs = slowTimeSignal.signalInfo.PRF;
                fDopplerMax = slowTimeSignal.signalInfo.PRF/2;
                obj.velocityMax = fdoppler2vel(fDopplerMax, fc);
            end

            T = size(slowTimeSignal.signal,2) / slowTimeSignal.signalInfo.PRF;  % duration [s]


            x.signal = signal;      % signal
            x.fs = fs;              % szybkosc probkowania
            x.N = length(signal);   % dlugosc sygnalu
            x.T = T;                % czas trwania sygnalu
            % parametry przetwrzania
            fwhm2SigmaRatio = 2*sqrt(2*log(2)); % ~ 2.35
            sigma_s = obj.windowWidth/fwhm2SigmaRatio;    % std of window (seconds)
            sigma = sigma_s * fs; % std of window (samples)
            gamma_K = 1e-4;     % prog przyciecia nieskonczonego okna Gaussa (Warning: unused in FFT method)

            % vDopplerResolution -> fDopplerResolution -> windowLength -> N_FFT
            fDopplerResolution = vel2fdoppler(obj.velocityResolution,fc);
            N_FFT = fs/fDopplerResolution;       % ilosc punktow na osi czestotliwosci
            CR_win = 0;         % chirp rate okna analizy
            method = 'FFT';     % metoda obliczania FFT
            % obliczamy STFT, ogolnie na 2 sposoby (ostatni argument - 'ptByPt' lub 'FFT'), obie implementacje
            % potrzebne - FFT jest szybsze, ale obliczanie punkt po punkie pozwala w prosty sposob wyodrebnic
            % mody oraz wykonac transformacje odwrotna
            obj.S = Gab_STFT(x, N_FFT, sigma, gamma_K, CR_win*(x.fs^2), method);
            
            obj.f_ax = linspace(-fDopplerMax, fDopplerMax, N_FFT);     % os czestotliwosci [Hz]
            obj.v_ax = fdoppler2vel(obj.f_ax,fc); % [m/s]
            obj.t_ax = (0 : (length(signal)-1)) / fs;             % os czasu [s]

            % synchrosqueezing wertykalny 1. rzedu
            IFreq = Gab_Get_IFreq_Est(obj.rank, x, N_FFT, sigma, gamma_K, CR_win/fs/fs, method);
            obj.SE = Gab_TF_V_Synchrosqueezing(obj.S, IFreq, method);
            
            L = sigma;
            M = N_FFT;
            method_extract = "sstft"; % "sstft" "stft" "hssft"
            freq_neighbor = abs(vel2fdoppler(obj.filterWidth, fc));
            [obj.breathIQ, obj.heartbeatIQ,ridge,mask,breath_sp,heartbeat_sp] =...
                obj.extract_vs_sstft(obj.SE, L,M, method_extract,fs,freq_neighbor);
            

            hb_env_imag = envelope(imag(obj.heartbeatIQ),round(fs*obj.rmsEnvelopeWidth),"rms");
            hb_env_real = envelope(real(obj.heartbeatIQ),round(fs*obj.rmsEnvelopeWidth),"rms");
            obj.heartbeatEnvelope = hb_env_imag + hb_env_real;
            

        end
    end

    methods (Access=private)
        function [breath, heartbeat,ridge,mask,breath_sp,heartbeat_sp] = extract_vs_sstft(sp,L,M, method,fs, neigh_width_Hz)
            %EXTRACT_BREATH Summary of this function goes here
            %   Detailed explanation goes here
            % neigh_width_Hz - total frequency neighbor width [Hz]
            
            f = 1:size(sp,1);
            ridge = tfridge(sp,f,1,'NumRidges',1,'NumFrequencyBins',4);
            neigh = round(neigh_width_Hz/fs*size(sp,1) / 2 - 0.5);
            
            
            mask = zeros(size(sp));
            
            
            for ridge_nr = 1:size(ridge,2)
                for k = 1:size(sp,2)
                    row_idxes = ridge(k,ridge_nr)-neigh:ridge(k,ridge_nr)+neigh;
                    row_idxes = row_idxes(row_idxes >= 1 & row_idxes < size(sp,1));
                    mask(row_idxes,k) = 1;
                end
            end
            
            
            
            breath_sp = sp.*mask;
            heartbeat_sp = sp.*~mask;
            
            if(method == "sstft")
                breath = Gab_ISSTFT(breath_sp,L,M);
                heartbeat = Gab_ISSTFT(heartbeat_sp,L,M);
            elseif(method == "stft")
                breath = Gab_ISTFT(breath_sp,L,M, 1:M);
                heartbeat = Gab_ISTFT(heartbeat_sp,L,M, 1:M);
            elseif(method == "hssft")
                breath = Gab_IHSSFT(breath_sp,L,M);
                heartbeat = Gab_IHSSFT(heartbeat_sp,L,M);
            else
                error("invalid method")
            end
            
        end


    end
end

