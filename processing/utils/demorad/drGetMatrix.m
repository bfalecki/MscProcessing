function data_matr = drGetMatrix(data,cfg)
    %DRGETMATRIX
    % get matrix from raw data of XY-Demorad
    samples_per_pulse = cfg.SamplingFreq / cfg.PRF;
    data_matr = reshape(data, samples_per_pulse, []);
    if(cfg.Carrier < 100e9)
        % when 24 GHz module, the data is conjugated!!
        data_matr = conj(data_matr);
    end
end

