% ASSUMES that the speechmatics data is in a .json (preferred) or .csv in the same folder as the audio, with a file name that's identical except for file extension
% INPUTS:
%   filePath - path to a .wav file
% RETURNS:
%   wordInfo
function wordInfo = LoadSpeechmatics4Audio(filePath)
    validateattributes(filePath, {'char'}, {'nonempty'}, 1);
    assert(endsWith(lower(filePath), '.wav'));

    jsonFilePath = regexprep(filePath, '\.wav', '.json');
    csvFilePath  = regexprep(filePath, '\.wav', '.csv');

    if logical(exist(jsonFilePath, 'file'))
        text = loadjson(jsonFilePath);
        wordInfo = text.words; % timepoints expected to be in units of SECONDS
    elseif logical(exist(csvFilePath, 'file'))
        fid = fopen(csvFilePath);
        text = textscan(fid, '%s,%f,%f', 'headerlines', 0);
        fclose(fid);
        wordInfo = cell(numel(text), 1);
        for j = 1:numel(wordInfo)
            wordInfo{j} = struct('name', text{j,1}, 'time', text{j,2}, 'duration', text{j,3}); % time and duration expected to be in units of SECONDS
        end
        error('^validate');
    else
        warning([jsonFilePath,' and ',csvFilePath,' both missing!!!']);
        wordInfo = [];
    end
end