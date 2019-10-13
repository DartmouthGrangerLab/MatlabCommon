%Eli Bowen
%9/12/2019
%creates a pbs file and submits a job to the cluster
%INPUTS:
%   pbsFolder - folder where the pbs file, and job output files, will be stored
%   pbsFileName - name of the .pbs file (not including a path)
%   matlabCode2Execute - matlab code to execute on the worker node
%   jobName - name of the job for your records (can be any string with no spacing)
%   wallTime - string representing the walltime of the job (max run time) in format D:HH:MM:SS (days hours mins secs)
%   ppn - processors per node (e.g. 8)
function [] = CreateAndSubmitPBSFile (pbsFolder, pbsFileName, matlabCode2Execute, jobName, wallTime, ppn)
    validateattributes(pbsFolder, {'char'}, {'nonempty'}, 1);
    validateattributes(pbsFileName, {'char'}, {'nonempty'}, 2);
    validateattributes(matlabCode2Execute, {'char'}, {'nonempty'}, 3);
    validateattributes(jobName, {'char'}, {'nonempty'}, 4);
    validateattributes(wallTime, {'char'}, {'nonempty'}, 5);
    validateattributes(ppn, {'numeric'}, {'scalar'}, 6);
    assert(endsWith(pbsFileName, '.pbs'));
    assert(isempty(regexp(jobName, '\s', 'ONCE'))); %no whitespace allowed
    assert(isempty(regexp(wallTime, '\s', 'ONCE'))); %no whitespace allowed
    
    %potential future parameters
    releaseYear = 2019;
    needJVM = false;
    email = 'efwb001@gmail.com'; %OPTIONAL
    feature = 'bigmem';
    %can do feature='bigmem' and ppn=16
    %can do feature='cellf' and ppn=48
    %can do feature='cellj' and ppn=12
    %can do feature='cellm' and ppn=16 for a whole node with 128 GB of ram
    %can do feature='celln' and ppn=20 for a whole node with 384 GB of ram
    %can do feature='el7|cellg' and ppn=16 (el7 is later numbered k nodes) (both are 128gig 16-core centos7 nodes)
    
    jvmTxt = '-nojvm';
    if needJVM
        jvmTxt = '';
    end
    
    if ~exist(pbsFolder, 'dir')
        mkdir(pbsFolder);
    end
    
    fileID = fopen(fullfile(pbsFolder, pbsFileName), 'w');
    fprintf(fileID, '#!/bin/bash -l\n');
    fprintf(fileID, ['#PBS -N ',jobName,'\n']);
    if exist('email', 'var') && ~isempty(email)
        fprintf(fileID, ['#PBS -M ',email,'\n']);
    end
    fprintf(fileID, ['#PBS -l walltime=',wallTime,'\n']);
    fprintf(fileID, ['#PBS -l feature="',feature,'"\n']);
    fprintf(fileID, ['#PBS -l nodes=1:ppn=',num2str(ppn),'\n']);
    fprintf(fileID, ['#PBS -o ',pbsFolder,'\n']);
    fprintf(fileID, '#PBS -j oe\n');
    fprintf(fileID, 'sleep 2;\n'); %2sec
    if releaseYear >= 2019
        fprintf(fileID, 'scl enable devtoolset-6 bash;'); %only needed when using mex with r2019a+
    end
    fprintf(fileID, ['module load matlab/r',num2str(releaseYear),'a;\n']);
    if releaseYear >= 2019
        fprintf(fileID, ['matlab -nodesktop -nodisplay ',jvmTxt,' -batch "',matlabCode2Execute,'";\n']);
    else %legacy
        fprintf(fileID, ['matlab -nodesktop -nodisplay ',jvmTxt,' -r "',matlabCode2Execute,';exit;";\n']);
    end
    fprintf(fileID, 'exit 0\n');
    fclose(fileID);
    disp(['submitting: qsub ',fullfile(pbsFolder, pbsFileName)]);
    [status,cmdout] = system(['qsub ',fullfile(pbsFolder, pbsFileName)], '-echo'); %will wait until command is executed
    if status ~= 0
        error(['qsub error ',num2str(status),': ',cmdout]);
    end
    
    pause(15); %just to give the job server a break
%     pause(220); %wait for job to start, matlab can't start parpools simultaneously at >1 location on the same network file system :(
end