%Eli Bowen
%5/20/2020
%wrapper around a matlab file exchange project for loading midi files (https://www.mathworks.com/matlabcentral/fileexchange/27470-midi-tools)
%INPUT:
%	filepath
%RETURNS:\
%   descriptors - cell aray of file descriptors for each file
%   noteList - N x 7 matrix:
%       noteList(:,1) is pitch (60 --> C4 = middle C)
%       noteList(:,2) is velocity
%       noteList(:,3) is note start in seconds from start of file
%       noteList(:,4) is note start in seconds from start of noteList
%       noteList(:,5) is note duration in seconds
%       noteList(:,6) is channel
%       noteList(:,7) is track/file number (index into descriptors)
function [descriptors,noteList] = GetMidis (filePath)
    rootPath = '/pdata/ebowen/MatlabCommon';
    if isempty(StringFind(javaclasspath(), fullfile(rootPath, 'frontends', 'aud_midi', 'KaraokeMidiJava.jar'), true)) %for performance
        javaaddpath(fullfile(rootPath, 'frontends', 'aud_midi', 'KaraokeMidiJava.jar'));
    end
    
    [~,descriptors,noteMat] = GetMidisHelper(filePath, {}, 0, {}, '');
    %noteMat{i}(:,1) is start beats (for file descriptors{i})
    %noteMat{i}(:,2) is duration beats (for file descriptors{i})
    %noteMat{i}(:,3) is channel (for file descriptors{i})
    %noteMat{i}(:,4) is pitch (for file descriptors{i})
    %noteMat{i}(:,5) is velocity (for file descriptors{i})
    %noteMat{i}(:,6) is start seconds (for file descriptors{i})
    %noteMat{i}(:,7) is duration in seconds (for file descriptors{i})
    N = sum(cellfun(@numel, noteMat)) / 7;
    noteList = zeros(N, 7);
    count = 1;
    for i = 1:numel(noteMat)
        noteList(count:count+size(noteMat{i}, 1)-1,1) = noteMat{i}(:,4);
        noteList(count:count+size(noteMat{i}, 1)-1,2) = noteMat{i}(:,5);
        noteList(count:count+size(noteMat{i}, 1)-1,3) = noteMat{i}(:,6);
        noteList(count:count+size(noteMat{i}, 1)-1,4) = noteMat{i}(:,6) + noteList(max(count-1, 1),4) + noteList(max(count-1, 1),5);
        noteList(count:count+size(noteMat{i}, 1)-1,5) = noteMat{i}(:,7);
        noteList(count:count+size(noteMat{i}, 1)-1,6) = noteMat{i}(:,3);
        noteList(count:count+size(noteMat{i}, 1)-1,7) = i;
        count = count + size(noteMat{i}, 1);
    end
end


function [count,descriptors,noteMat] = GetMidisHelper (filePath, noteMat, count, descriptors, append)
    listing = dir(filePath);
    for i = 1:numel(listing)
        if ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            if listing(i).isdir
                [count,descriptors,noteMat] = GetMidisHelper(fullfile(filePath, listing(i).name), noteMat, count, descriptors, [append,'_',strrep(listing(i).name, '_', '-')]);
            elseif ~isempty(regexp(lower(listing(i).name), '\.mid$', 'ONCE')) || ~isempty(regexp(lower(listing(i).name), '\.kar$', 'ONCE'))
                try
                    note_matrix = readmidi_java(fullfile(filePath, listing(i).name));
                    
                    count = count + 1;
                    descriptors{count} = strrep(regexprep(regexprep(lower(listing(i).name), '\.mid$', ''), '\.kar$', ''), '_', '-');
                    if ~isempty(append)
                        descriptors{count} = [append,'_',descriptors{count}];
                    end
                    noteMat{count} = note_matrix;
                catch ex
                    disp(['error parsing [',listing(i).name,']:']);
                    disp(ex.message);
                end
            end
        end
    end
end