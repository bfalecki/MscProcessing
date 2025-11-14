function dechirped = read_demorad(filename)

    filename = char(filename);

    fid   = fopen(filename);
    if (fid == -1)
      disp(['Unable to open file ' filename]);
      return
    end
    data  = fread(fid, Inf, 'int16');
    ch0 = data(1:2:end);
    ch1 = data(2:2:end);
    dechirped = complex(ch0,ch1);

    fs = 1e6;


end