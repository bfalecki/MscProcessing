function jsonstruct = readJson(path)
%READJSON read json file into struct
    fid = fopen(path);
    raw = fread(fid,inf);
    str = char(raw');
    fclose(fid);
    jsonstruct = jsondecode(str);
end

