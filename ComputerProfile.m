% Eli Bowen
% 7/6/2021
% computer profiles
% add your computer here!
% to determine your username, call NameOfUser()
% to determine your computer's name, call NameOfComputer()
% all directory paths should be absolute
% RETURNS:
%   profile - a struct with fields:
%       .dataset_dir - path to the directory containing all datasets
%       .cache_dir - path to the cache directory
function [profile] = ComputerProfile ()
    %   username  computername                dataset root dir         cache storage dir
    computerProfile = {...
        'f0018x6','boskop.dartmouth.edu',     '/pdata/ebowen/datasets','/pdata/ebowen/tempcache';... % Eli on boskop
        'f0018x6','*.discovery.dartmouth.edu','/pdata/ebowen/datasets','/pdata/ebowen/tempcache';... % Eli on discovery cluster
        'ebowen', 'bigbrain.dartmouth.edu',   '?',                     '?';...                       % Eli on bigbrain
        'eli',    'eb-inspiron',              'Z:\datasets',           'D:\tempcache';...            % Eli's laptop
        'eli',    'eb-desktop',               'Z:\datasets',           'D:\tempcache';...            % Eli's desktop
        };

    %% find current computer's profile
    profileIdx = find(strcmpi(computerProfile(:,1), NameOfUser()) & strcmpi(computerProfile(:,2), NameOfComputer()));
    if isempty(profileIdx)
        profileIdx = find(strcmp(computerProfile(:,1), NameOfUser()) & endsWith(computerProfile(:,2), NameOfComputer()));
        if isempty(profileIdx) || numel(profileIdx) > 1
            error('unrecognized computer / user - add your computer to MatlabCommon ComputerProfile.m');
        end
    end
    
    profile = struct();
    profile.dataset_dir = computerProfile{profileIdx,3};
    profile.cache_dir   = computerProfile{profileIdx,4};

    if ~exist(profile.cache_dir, 'dir')
        mkdir(profile.cache_dir);
    end
end
