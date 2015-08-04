%Prints the current time to standard out
function [] = TimeStamp ()
    fprintf(['Current time = ',datestr(now,'mm/dd/yyyy HH:MM:SS:FFF'),'\n']);
end