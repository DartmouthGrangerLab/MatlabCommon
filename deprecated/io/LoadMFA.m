% deprecated
function alignment = LoadMFA(filePath)
    validateattributes(filePath, {'char'}, {'nonempty'}, 1);
    assert(endsWith(lower(filePath), '.csv'));

    fileID = fopen(filePath, 'r');

    header = strsplit(fgetl(fileID), ',', 'CollapseDelimiters', false);
    alignment = struct();
    alignment.phonemes = {};
    alignment.startTime = []; % in seconds?
    alignment.endTime = []; % in seconds?
    count = 1;
    while ~feof(fileID)
        text = strsplit(fgetl(fileID), ',', 'CollapseDelimiters', false);
        assert(numel(text) == numel(header));
        if strcmp(text{4}, 'phones')
            alignment.phonemes{count} = text{3};
            alignment.startTime(count) = str2double(text{1});
            alignment.endTime(count) = str2double(text{2});
            count = count + 1;
        end
    end
    fclose(fileID);
end