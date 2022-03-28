% Eli Bowen 6/3/2020
% RETURNS:
%   totalMemory - scalar (numeric) total memory in gigabytes (may not be a round number, or exactly what the ram packaging said)
function totalMemory = ComputerRAMSize()
    if ispc()
        [~,sys] = memory();
        totalMemory = sys.PhysicalMemory.Total / 1024 / 1024 / 1024;
    else % ismac() or isunix()
        [status,cmdout] = system('vmstat -s | grep "total memory"');
        assert(status == 0);
        cmdout = strsplit(cmdout);
        totalMemory = str2double(cmdout{2});
        if strcmp(cmdout{3}, 'K')
            totalMemory = totalMemory / 1024 / 1024;
        else
            error('unknown vmstat output format');
        end
        % never tested on mac
    end
end