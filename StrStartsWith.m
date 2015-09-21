%Determines whether a string starts with a specified pattern
%Inputs:
%   s - string to search
%   pat - string which may or may not be at the start (NOT a regular expression)
%Outputs:
%	trueFalse - whether the string s ends with a sub-string pat
%Created by Dahua Lin, on Oct 9, 2008 (http://www.mathworks.com/matlabcentral/fileexchange/21710-string-toolkits/content/strings/strendswith.m)
%Adapted by Eli Bowen
function [trueFalse] = StrStartsWith (s, pat)
    sl = length(s);
    pl = length(pat);

    trueFalse = (sl >= pl && strcmp(s(1:pl), pat)) || isempty(pat);
end