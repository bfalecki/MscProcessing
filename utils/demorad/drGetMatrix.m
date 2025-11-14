function data_matr = drGetMatrix(data,cfg)
    %DRGETMATRIX
    % get matrix from raw data of XY-Demorad
    samples_per_pulse = cfg.SamplingFreq / cfg.PRF;
    data_matr = reshape(data, samples_per_pulse, []);

end

