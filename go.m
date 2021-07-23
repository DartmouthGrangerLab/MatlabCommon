function [] = go (nThreads)
    dir = fileparts(fileparts(which('go'))); % dir is the folder that MatlabCommon resides in (up 2 from go.m)
    cd(dir);
    pause(3);

    if exist('nThreads', 'var') && ~isempty(nThreads) && nThreads > 1
        parpool(nThreads, 'SpmdEnabled', false);
    end

    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    format compact;

    %------------ FreeSurfer -----------------------------%
    % fshome = getenv('FREESURFER_HOME');
    % fsmatlab = sprintf('%s/matlab',fshome);
    % if (exist(fsmatlab) == 7)
    %     addpath(genpath(fsmatlab));
    % end
    % clear fshome fsmatlab;
    % %-----------------------------------------------------%
    % %------------ FreeSurfer FAST ------------------------%
    % fsfasthome = getenv('FSFAST_HOME');
    % fsfasttoolbox = sprintf('%s/toolbox',fsfasthome);
    % if (exist(fsfasttoolbox) == 7)
    %     path(path,fsfasttoolbox);
    % end
    % clear fsfasthome fsfasttoolbox;
    %-----------------------------------------------------%
end