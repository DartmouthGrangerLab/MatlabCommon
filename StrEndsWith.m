%Determines whether a string ends with a specified pattern
%Inputs:
%   s - string to search
%   pat - string which may or may not be at the end (NOT a regular expression)
%Outputs:
%	trueFalse - whether the string s ends with a sub-string pat
%Created by Dahua Lin, on Oct 9, 2008 (http://www.mathworks.com/matlabcentral/fileexchange/21710-string-toolkits/content/strings/strendswith.m)
%Adapted by Eli Bowen
function [trueFalse] = StrEndsWith (s, pat)
    sl = length(s);
    pl = length(pat);

    trueFalse = (sl >= pl && strcmp(s(sl-pl+1:sl), pat)) || isempty(pat);
end