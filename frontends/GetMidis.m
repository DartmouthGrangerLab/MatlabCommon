%Eli Bowen
%5/20/2020
%wrapper around a matlab file exchange project for loading midi files (https://www.mathworks.com/matlabcentral/fileexchange/27470-midi-tools)
%INPUT:
%	path - folder or valid midi file
%RETURNS:
%   noteList - N x 7 matrix:
%       noteList(:,1) is pitch (60 --> C4 = middle C)
%       noteList(:,2) is velocity
%       noteList(:,3) is note start in seconds from start of track/file
%       noteList(:,4) is note duration in seconds
%       noteList(:,5) is channel
%       noteList(:,6) is track/file number (index into descriptors)
%   descriptors - 1 x numTracks cell array of file descriptors
%   trackDuration - 1 x numTracks double array of durations in seconds
function [noteList,descriptors,trackDuration] = GetMidis (path)
    rootPath = '/pdata/ebowen/MatlabCommon';
    if isempty(StringFind(javaclasspath(), fullfile(rootPath, 'frontends', 'aud_midi', 'KaraokeMidiJava.jar'), true)) %for performance
        javaaddpath(fullfile(rootPath, 'frontends', 'aud_midi', 'KaraokeMidiJava.jar'));
    end
    
    [~,descriptors,noteMat] = Helper(path, {}, 0, {}, '');
    %noteMat{i}(:,1) is start beats (for file descriptors{i})
    %noteMat{i}(:,2) is duration beats (for file descriptors{i})
    %noteMat{i}(:,3) is channel (for file descriptors{i})
    %noteMat{i}(:,4) is pitch (for file descriptors{i})
    %noteMat{i}(:,5) is velocity (for file descriptors{i})
    %noteMat{i}(:,6) is start seconds (for file descriptors{i})
    %noteMat{i}(:,7) is duration in seconds (for file descriptors{i})
    N = sum(cellfun(@numel, noteMat)) / 7;
    noteList = zeros(N, 6);
    count = 1;
    for i = 1:numel(noteMat)
        noteList(count:count+size(noteMat{i}, 1)-1,1) = noteMat{i}(:,4);
        noteList(count:count+size(noteMat{i}, 1)-1,2) = noteMat{i}(:,5);
        noteList(count:count+size(noteMat{i}, 1)-1,3) = noteMat{i}(:,6);
        noteList(count:count+size(noteMat{i}, 1)-1,4) = noteMat{i}(:,7);
        noteList(count:count+size(noteMat{i}, 1)-1,5) = noteMat{i}(:,3);
        noteList(count:count+size(noteMat{i}, 1)-1,6) = i;
        count = count + size(noteMat{i}, 1);
    end
    trackDuration = zeros(1, numel(descriptors));
    for i = 1:numel(descriptors)
        idx = find(noteList(:,6)==i, 1, 'last');
        trackDuration(i) = noteList(idx,3) + noteList(idx,4);
    end
end


function [count,descriptors,noteMat] = Helper (path, noteMat, count, descriptors, append)
    listing = dir(path);
    for i = 1:numel(listing)
        if listing(i).isdir && ~strcmp(listing(i).name, '.') && ~strcmp(listing(i).name, '..')
            [count,descriptors,noteMat] = Helper(fullfile(path, listing(i).name), noteMat, count, descriptors, [append,'_',strrep(listing(i).name, '_', '-')]);
        end
    end
    for i = 1:numel(listing)
        if ~listing(i).isdir
            [~,fileNameNoExt,ext] = fileparts(listing(i).name);
            if strcmpi(ext, '.mid') || strcmpi(ext, '.kar')
                try
                    note_matrix = readmidi_java(fullfile(path, listing(i).name));
                    noteMat{count+1} = note_matrix;

                    descriptors{count+1} = strrep(lower(fileNameNoExt), '_', '-');
                    if ~isempty(append)
                        descriptors{count+1} = [append,'_',descriptors{count+1}];
                    end
                    count = count + 1;
                catch ex
                    disp(['error parsing [',listing(i).name,']:']);
                    disp(ex.message);
                end
            end
        end
    end
end