% Eli Bowen
% 6/10/2021
% returns the mfilename() of caller's caller (minus '.m')
% if the caller's caller is a class method, this is the class name
% if the caller's caller is a function,     this is the function name
% if the caller's caller is a script,       this is the script name
function [ret] = CallingFile ()
    st = dbstack();
    [~,ret,~] = fileparts(st(end-1).file); % end would be CallingFile()'s caller - I want my caller's caller
end