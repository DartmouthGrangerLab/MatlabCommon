% Eli Bowen
% 7/6/2021
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
        %   username      computername                dataset root dir         cache storage dir
        profiles = {...
            'f0018x6',   'boskop.dartmouth.edu',     '/pdata/ebowen/datasets','/pdata/ebowen/tempcache';... % Eli on boskop
            'f0018x6',   '*.discovery.dartmouth.edu','/pdata/ebowen/datasets','/pdata/ebowen/tempcache';... % Eli on discovery cluster
            'ebowen',    'bigbrain.dartmouth.edu',   '?',                     '?';...                       % Eli on bigbrain
            'eli',       'eb-inspiron',              'Z:\datasets',           'D:\tempcache';...            % Eli's laptop
            'eli',       'eb-desktop',               'D:\Projects\datasets',  'D:\tempcache';...            % Eli's desktop
            'grangerlab','grangerlab-aspire-m3985',  '/home/grangerlab/Desktop/Projects/Logicnet/datasets','/home/grangerlab/Desktop/Projects/Logicnet/tempcache';... % Anand's desktop
            }
    end


    methods (Static)
        function [x] = DatasetDir()
            idx = ComputerProfile.FindProfile();
            x = ComputerProfile.profiles{idx,3};
        end
        function [x] = CacheDir()
            idx = ComputerProfile.FindProfile();
            x = ComputerProfile.profiles{idx,4};
            if ~exist(x, 'dir')
                mkdir(x);
            end
        end
    end


    methods (Static, Access = private)
        function [idx] = FindProfile()
            idx = find(strcmpi(ComputerProfile.profiles(:,1), NameOfUser()) & strcmpi(ComputerProfile.profiles(:,2), NameOfComputer()));
            if isempty(idx)
                idx = find(strcmp(ComputerProfile.profiles(:,1), NameOfUser()) & endsWith(ComputerProfile.profiles(:,2), NameOfComputer()));
                if isempty(idx) || numel(idx) > 1
                    error('unrecognized computer / user - add your computer to MatlabCommon ComputerProfile.m');
                end
            end
        end
    end
    
    
    % below just temporary for backwards compatability
    properties (Dependent) % computed, derivative properties
        dataset_dir
        cache_dir
    end
    methods
        function [x] = get.dataset_dir(obj)
            x = ComputerProfile.DatasetDir();
        end
        function [x] = get.cache_dir(obj)
            x = ComputerProfile.CacheDir();
        end
    end
end