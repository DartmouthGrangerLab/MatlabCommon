function [] = go(n_threads)
%     dir = fileparts(fileparts(which('go'))); % dir is the folder that MatlabCommon resides in (up 2 from go.m)
%     cd(dir);
%     pause(3);

    if exist('n_threads', 'var') && ~isempty(n_threads) && n_threads > 1
        parpool(n_threads, 'SpmdEnabled', false);
    end

    warning('off', 'MATLAB:MKDIR:DirectoryExists');
    warning('off', 'MATLAB:structOnObject'); % I like to call struct() on an object when I call struct on an object...
    warning('off', 'MATLAB:table:PreallocateCharWarning'); % shh
    format compact % for terminal printing

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