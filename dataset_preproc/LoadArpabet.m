%Eli Bowen
%2/14/2018 (earlier copy from 2017 was in FindGoodWords.m)
function [arpabetDictEnglish,arpabetDictPhonetic] = LoadArpabet (dictPath)
    %% Load arpabet
    %way 1 (not working)
    % arpabetDict = readtable(dictPath, 'Delimiter', ',', 'ReadVariableNames', false, 'CommentStyle', ';');
    %way 2
    fileID = fopen(dictPath);
    arpabetDict = textscan(fileID, '%s', 'EndOfLine', '\r\n', 'Delimiter', '\n', 'CommentStyle', ';');
    arpabetDict = arpabetDict{1};
    fclose(fileID);
    clearvars fileID;

    arpabetDictEnglish = cell(numel(arpabetDict), 1);
    arpabetDictPhonetic = cell(numel(arpabetDict), 1);
    for i = 1:numel(arpabetDict)
        spaceLocs = strfind(arpabetDict{i}, ' ');
        arpabetDictEnglish{i} = strtrim(lower(arpabetDict{i}(1:spaceLocs(1)-1)));
        arpabetDictPhonetic{i} = strtrim(arpabetDict{i}(spaceLocs(1)+1:end));
    end
end