% Eli Bowen 2/14/2018 (earlier copy from 2017 was in FindGoodWords.m)
% loads the CMU phonetic dictionary (file named e.g. 'cmudict-0.7b.txt')
% INPUTS
%   path - (char) full path of the file
% RETURNS
%   arpabetDictEnglish
%   arpabetDictPhonetic
function [arpabetDictEnglish,arpabetDictPhonetic] = LoadArpabet(path)
    %% Load arpabet
    % way 1 (not working)
    % arpabetDict = readtable(path, 'Delimiter', ',', 'ReadVariableNames', false, 'CommentStyle', ';');
    % way 2
    fileID = fopen(path);
    arpabetDict = textscan(fileID, '%s', 'EndOfLine', '\r\n', 'Delimiter', '\n', 'CommentStyle', ';');
    arpabetDict = arpabetDict{1};
    fclose(fileID);
    clearvars fileID

    arpabetDictEnglish = cell(numel(arpabetDict), 1);
    arpabetDictPhonetic = cell(numel(arpabetDict), 1);
    for i = 1 : numel(arpabetDict)
        spaceLocs = strfind(arpabetDict{i}, ' ');
        arpabetDictEnglish{i} = strtrim(lower(arpabetDict{i}(1:spaceLocs(1)-1)));
        arpabetDictPhonetic{i} = strtrim(arpabetDict{i}(spaceLocs(1)+1:end));
    end
end