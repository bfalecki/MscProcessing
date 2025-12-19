function data_matr = drGetMatrix(data,signalInfo)
    %DRGETMATRIX
    % get matrix from raw data of XY-Demorad
    % data - vector
    % signalInfo - instance of SignalInfo

    samples_per_pulse = signalInfo.samplingFrequency / signalInfo.PRF;
    data_matr = reshape(data, samples_per_pulse, []);
    if(signalInfo.carrierFrequency < 100e9)
        % when 24 GHz module, the data is conjugated!!
        data_matr = conj(data_matr);
    end
end

