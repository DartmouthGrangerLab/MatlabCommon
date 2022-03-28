% determines whether a string ends with a specified pattern
% INPUTS:
%   s - string to search
%   pat - string which may or may not be at the end (NOT a regular expression)
% Outputs:
%	tf - scalar (logical) whether the string s ends with a sub-string pat
% created by Dahua Lin, on Oct 9, 2008 (http://www.mathworks.com/matlabcentral/fileexchange/21710-string-toolkits/content/strings/strendswith.m)
% adapted by Eli Bowen
% in newer releases, just use endsWith()
% see also endsWith
function tf = StrEndsWith(s, pat)
    sl = length(s);
    pl = length(pat);

    tf = (sl >= pl && strcmp(s(sl-pl+1:sl), pat)) || isempty(pat);
end