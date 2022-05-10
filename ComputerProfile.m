% computer profiles
% add your computer here!
% to determine your username, call NameOfUser()
% to determine your computer's name, call NameOfComputer()
% all directory paths should be absolute
% RETURNS:
%   profile with fields:
%       .dataset_dir - path to the directory containing all datasets
%       .cache_dir   - path to the cache directory
classdef ComputerProfile
    properties (Constant)
        %   username@computername                dataset root dir              cache storage dir
        profiles = {...
            'f0018x6@boskop.dartmouth.edu',      '/pdata/ebowen/datasets',     '/pdata/ebowen/tempcache';... % Eli on boskop
            'f0018x6@*.discovery.dartmouth.edu', '/pdata/ebowen/datasets',     '/pdata/ebowen/tempcache';... % Eli on discovery cluster
            'ebowen@bigbrain.dartmouth.edu',     '?',                          '?';...                       % Eli on bigbrain
            'eli@eb-inspiron',                   'Z:\datasets',                'D:\tempcache';...            % Eli's laptop
            'eli@eb-desktop',                    'D:\Projects\datasets',       'D:\tempcache';...            % Eli's desktop
            'grangerlab@grangerlab-aspire-m3985','/home/grangerlab/Desktop/Projects/Logicnet/datasets','/home/grangerlab/Desktop/Projects/Logicnet/tempcache'; % Anand's desktop
            'cfoye@clays-macbook-pro.local',     '/Users/cfoye/Granger/',      '/Users/cfoye/Granger/cache';... %Clay's macbook
            'rhg@rhg-7.local',                   '/Users/rhg/Documents/MATLAB','/Users/rhg/Documents/MATLAB/logicnet2/cache';...
            }
    end


    methods (Static)
        function x = DatasetDir()
            idx = ComputerProfile.FindProfile();
            if isempty(idx) || numel(idx) > 1
                error('unrecognized computer / user - add your computer to MatlabCommon ComputerProfile.m');
            end
            if isempty(idx) || numel(idx) > 1 || isempty(ComputerProfile.profiles{idx,2})
                x = fullfile(ComputerProfile.MatlabCommonDir(), '..', 'datasets'); % default to a folder named "datasets" next to MatlabCommon
            else
                x = ComputerProfile.profiles{idx,2};
            end
            
            if ~exist(x, 'dir')
                mkdir(x);
            end
        end


        function x = CacheDir()
            idx = ComputerProfile.FindProfile();
            if isempty(idx) || numel(idx) > 1 || isempty(ComputerProfile.profiles{idx,3})
                x = fullfile(tempdir(), 'matlabcachedir');
            else
                x = ComputerProfile.profiles{idx,3};
            end
            
            if ~exist(x, 'dir')
                mkdir(x);
            end
        end


        function x = MatlabCommonDir()
             [x,~,~] = fileparts(mfilename('fullpath'));
        end
    end


    methods (Static, Access = private)
        function idx = FindProfile()
            idx = find(strcmpi(ComputerProfile.profiles(:,1), [NameOfUser(),'@',NameOfComputer()]));
            if isempty(idx)
                idx = find(startsWith(ComputerProfile.profiles(:,1), [NameOfUser(),'@'], 'IgnoreCase', true) & endsWith(ComputerProfile.profiles(:,2), NameOfComputer(), 'IgnoreCase', true));
            end
        end
    end


    % below just temporary for backwards compatability
    properties (Dependent) % computed, derivative properties
        dataset_dir
        cache_dir
    end
    methods
        function x = get.dataset_dir(obj)
            x = ComputerProfile.DatasetDir();
        end
        function x = get.cache_dir(obj)
            x = ComputerProfile.CacheDir();
        end
    end
end