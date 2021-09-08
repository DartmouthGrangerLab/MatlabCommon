% prints the current time to standard out
% optionally returns what it just printed
function [text] = TimeStamp ()
    text = ['current time = ',datestr(now,'mm/dd/yyyy HH:MM:SS:FFF')];
    fprintf('%s\n', text);
end