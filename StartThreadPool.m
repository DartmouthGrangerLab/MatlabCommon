%By Eli Bowen 2014
%Inputs:
%   hardware - OPTIONAL - string, one of 'discovery' or 'bigbrain' (else will create a local pool)
function [] = StartThreadPool (hardware)
    if nargin == 0
        hardware = '';
    end
    ver = version('-release'); %returns a string like '2014a'

    if strcmp(hardware, 'discovery') %------------------------------
        if str2double(ver(1:4)) < 2014
            if matlabpool('size') > 0
                matlabpool close;
            end
        else
            if ~isempty(gcp('nocreate'))
                delete(gcp('nocreate'));
            end
        end
        path('torque_1node_discovery.settings', path); %move profile to TOP of path
        prof = parallel.importProfile('torque_1node_discovery.settings');
        try
            if str2double(ver(1:4)) < 2014
                matlabpool open torque_1node_discovery;  %name of settings file
            else
                parpool(prof);
            end
        catch
            path('torque_1node_discovery.settings', path); %move profile to TOP of path
            prof = parallel.importProfile('torque_1node_discovery.settings');
            if str2double(ver(1:4)) < 2014
                matlabpool open torque_1node_discovery;  %name of settings file
            else
                parpool(prof);
            end
        end
        %matlabpool open local;  %this also works, but who knows what this profile has in it
        maxNumCompThreads(28); % limits total cores used
    elseif strcmp(hardware, 'bigbrain') %------------------------------
        try
            if str2double(ver(1:4)) < 2014
                matlabpool close;
            else
                delete(gcp('nocreate'));
            end
        end
        prof = parallel.importProfile('torque_8node_bigbrain.settings');
        try
        	if str2double(ver(1:4)) < 2014
                matlabpool open torque_8node_bigbrain;  %name of settings file
            else
                parpool(prof);
            end
        catch
            path('torque_8node_bigbrain.settings', path); %move profile to TOP of path
            prof = parallel.importProfile('torque_8node_bigbrain.settings');
            if str2double(ver(1:4)) < 2014
                matlabpool open torque_8node_bigbrain;  %name of settings file
            else
                parpool(prof);
            end
        end
        maxNumCompThreads(32); %limits total cores used
    elseif strcmp(hardware, 'boskop') %------------------------------
        nTries = 0;
        hadException = 1;
        while nTries < 10 && hadException == 1 %on boskop, running qsub twice within 30 seconds can cause parpool to fail because of a race condition
            hadException = 0;
            try
                if str2double(ver(1:4)) < 2014
                    if matlabpool('size') < 1
                        matlabpool(8);
                    end
                else
                    if isempty(gcp('nocreate'))
                        parpool(8);
                    end
                end
            catch myException
                disp(myException);
                hadException = 1;
            end
            nTries = nTries + 1;
        end
        if hadException == 1
            error('StartThreadPool(''boskop'') failed 10 times to create a parallel pool! Giving up.');
        end
    else %------------------------------
        if str2double(ver(1:4)) < 2014
            if matlabpool('size') < 1
                matlabpool(4);
            end
        else
            if isempty(gcp('nocreate'))
                parpool(4);
            end
        end
    end
end