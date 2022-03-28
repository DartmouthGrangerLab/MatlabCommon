% determines whether a string starts with a specified pattern
% Inputs:
%   s - string to search
%   pat - string which may or may not be at the start (NOT a regular expression)
% Outputs:
%	tf - whether the string s ends with a sub-string pat
% created by Dahua Lin, on Oct 9, 2008 (http://www.mathworks.com/matlabcentral/fileexchange/21710-string-toolkits/content/strings/strendswith.m)
% adapted by Eli Bowen
% in newer releases, just use startsWith()
% see also startsWith
function tf = StrStartsWith(s, pat)
    sl = length(s);
    pl = length(pat);

    tf = (sl >= pl && strcmp(s(1:pl), pat)) || isempty(pat);
end