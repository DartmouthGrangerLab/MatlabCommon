% Eli Bowen 6/3/2020
% RETURNS
%   totalMemory - scalar (numeric) total memory in gigabytes (may not be a round number, or exactly what the RAM packaging said)
function totalMemory = ComputerRAMSize()
    if ispc()
        [~,sys] = memory();
        totalMemory = sys.PhysicalMemory.Total / 1024 / 1024 / 1024;
    elseif islinux()
        [status,cmdout] = system('vmstat -s | grep "total memory"');
        assert(status == 0, ['vmstat failed with message: ',cmdout]);
        cmdout = strsplit(cmdout);
        totalMemory = str2double(cmdout{2});
        if strcmp(cmdout{3}, 'K')
            totalMemory = totalMemory / 1024 / 1024;
        else
            error('unknown vmstat output format');
        end
    elseif ismac()
        [status,cmdout] = system('sysctl hw.memsize');
        assert(status == 0, ['sysctl hw.memsize failed with message: ',cmdout]);
        cmdout = strsplit(cmdout);
        totalMemory = str2double(cmdout{2}); % should be in Bytes
        totalMemory = totalMemory / 1024 / 1024 / 1024;
    else
        error('unable to determine OS');
    end
end