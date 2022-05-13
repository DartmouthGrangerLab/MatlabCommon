% stops at first occurence of a line beginning with a colon (:) 
% INPUTS:
%   fid
% RETURNS:
%   result
%   line
%   pos
%   line_count
% modified by eli only for readability
function [result,line,pos,line_count] = findNextASFSection (fid)
    pos = 0;
    line_count = 0;
    line = [];
    while ~feof(fid)
        l = eatWhitespace(fgetl(fid));
        line_count = line_count + 1;
        if length(l) < 1
            continue;
        end
        if l(1) ~= ':'
            continue;
        else
            result = true;
            line = l;
            return;
        end
    end
    result = false;
end