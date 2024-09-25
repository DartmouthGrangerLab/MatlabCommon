% Eli Bowen 9/2024
function [] = SaveJSON(path, filename, x)
    assert(endsWith(filename, ".json"));

    encoded = jsonencode(x, ConvertInfAndNaN=false, PrettyPrint=false);

    % below is better than prettyprint, which puts every single number on its own line (but this is hacky)
    encoded = strrep(encoded, '{"', ['{',newline,'"']);
    encoded = strrep(encoded, '},', ['},',newline]);
    encoded = strrep(encoded, '":', '": ');
    encoded = strrep(encoded, ',"', ', "');

    fid = fopen(fullfile(path, filename), 'w');
    fprintf(fid, '%s', encoded);
    fclose(fid);
end