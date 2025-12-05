function dechirped = read_demorad(filename, opts)

arguments
    filename 
    opts.Samples = Inf % how many samples to read
    opts.SkipSamples = 0 % how many samples to skip on the beggining
end

    
    skipBytes = opts.SkipSamples*4;
    fields = opts.Samples * 2;

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

    fs = 1e6;


end