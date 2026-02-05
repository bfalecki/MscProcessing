function saveJson(outPathJson,str)
%SAVEJSON save struct to json file
    fprintf("Saving results to:\n  %s\n", outPathJson);
    jsonText = jsonencode(str, 'PrettyPrint', true);
    fid = fopen(outPathJson,'w');
    fwrite(fid, jsonText);
    fclose(fid);
end

