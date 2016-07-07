%By Eli Bowen 2014
%Inputs:
%   numThreads - number of threads requested. ignored exclusively when hardware = 'bigbrain'
%   hardware - OPTIONAL - one of 'bigbrain', 'discovery', or 'local' (default = local pool)
function [] = StartThreadPool (numThreads, hardware)
    if nargin == 0
        hardware = '';
    end
    ver = version('-release'); %returns a string like '2014a'
    
    try
        if str2double(ver(1:4)) < 2014
            matlabpool close;
        else
            delete(gcp('nocreate'));
        end
    end

    if strcmp(hardware, 'bigbrain') %------------------------------
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
    elseif strcmp(hardware, 'discovery') %------------------------------
        %method 1 (should work)
%         c = parcluster('local');
%         c.JobStorageLocation = fullfile(outputFolder, 'temp');
        
        %method 2 (should also work)
        nTries = 0;
        hadSuccess = 0;
        while nTries < 20 && hadSuccess == 0 %on discovery, running qsub twice within 30 seconds can cause parpool to fail because of a race condition
            %below method sometimes works, but occasionally breaks everything
            %if parpool() gives you a 'not enough parameters' error, delete the contents of ~/.matlab/local_cluster_jobs/R2015a/
%             try
%                 if str2double(ver(1:4)) < 2014
%                     if matlabpool('size') < 1
%                         matlabpool(numThreads);
%                     end
%                 else
%                     if isempty(gcp('nocreate'))
%                         parpool(numThreads);
%                     end
%                 end
%                 hadSuccess = 1;
%             catch myException
%                 disp(myException);
%             end
            
            try %use the power of... java!!!
                file = java.io.RandomAccessFile('StartThreadPool_lockfile.txt', 'rw'); %created in pwd
                fileChannel = file.getChannel();
                fileLock = fileChannel.tryLock();
                if ~isempty(fileLock) && fileLock.isValid() == 1
                    if str2double(ver(1:4)) < 2014
                        if matlabpool('size') < 1
                            matlabpool(numThreads);
                        end
                    else
                        if isempty(gcp('nocreate'))
                            parpool(numThreads);
                        end
                    end
                    fileLock.release();
                    clear fileLock fileChannel file;
                    hadSuccess = 1;
                else
                    disp('Another instance of matlab is executing StartThreadPool() - waiting to try again');
                end
            catch myException
                disp(myException);
            end
            
            pause(5);
            nTries = nTries + 1;
        end
        if hadSuccess == 0
            error(['StartThreadPool(',num2str(numThreads),', ''discovery'') failed 20 times to create a parallel pool! Giving up.']);
        end
    else %------------------------------
        if str2double(ver(1:4)) < 2014
            if matlabpool('size') < 1
                matlabpool(numThreads);
            end
        else
            if isempty(gcp('nocreate'))
                parpool(numThreads);
            end
        end
    end
end