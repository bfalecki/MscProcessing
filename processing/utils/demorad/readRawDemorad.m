function rawData = readRawDemorad(filename,signalInfo, opts)

arguments
    filename 
    signalInfo % instance of SignalInfo class
    opts.samples = Inf % how many samples to read
    opts.skipSamples = 0 % how many samples to skip on the beggining
    opts.Conjugated = 0 % if we want to apply conjugation (sometimes it is needed, sometimes not)
end

    
    skipBytes = opts.skipSamples*4;
    fields = opts.samples * 2;

    filename = char(filename);

    fid   = fopen(filename);
    if (fid == -1)
      disp(['Unable to open file ' filename]);
      return
    end
    fseek(fid,skipBytes,'bof');
    data  = fread(fid, fields, 'int16');
    fclose(fid);
    ch0 = data(1:2:end);
    ch1 = data(2:2:end);
    dechirped = complex(ch0,ch1);

    % add offset regarding opts.skipSamples
    signalInfo.timeStart = signalInfo.timeStart + seconds(opts.skipSamples/1e6);

    % conversion from vector to matrix
    data_matr = drGetMatrix(dechirped,signalInfo, "Conjugated", opts.Conjugated);

    rawData = RawData(data_matr,signalInfo);

end