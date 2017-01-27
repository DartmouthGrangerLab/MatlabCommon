% GETCOMPUTERNAME returns the name of the computer (hostname)
% name = getComputerName()
%
% WARN: output string is converted to lower case
%
%
% See also SYSTEM, GETENV, ISPC, ISUNIX
%
% m j m a r i n j (AT) y a h o o (DOT) e s
% (c) MJMJ/2007
% MOD: MJMJ/2013
%Pulled by Eli Bowen 1/2017 from https://www.mathworks.com/matlabcentral/fileexchange/16450-get-computer-name-hostname
function [name] = getComputerName ()
    [ret,name] = system('hostname');   

    if ret ~= 0
       if ispc
          name = getenv('COMPUTERNAME');
       else      
          name = getenv('HOSTNAME');      
       end
    end
    name = strtrim(lower(name));
end
