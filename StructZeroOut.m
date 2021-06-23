% Eli Bowen
% 6/19/2021
% zeros out every field of a struct (recursively), ignoring fields that are cells
% INPUTS:
%   s - scalar struct
% RETURNS:
%   s
function [s] = StructZeroOut (s)
    validateattributes(s, {'struct'}, {'nonempty','scalar'});
    
    fn = fieldnames(s);
    for i = 1:numel(fn)
        if isstruct(s.(fn{i}))
            s.(fn{i}) = StructZeroOut(s.(fn{i}));
        elseif ~iscell(s.(fn{i}))
            s.(fn{i})(:) = 0;
        end
    end
end