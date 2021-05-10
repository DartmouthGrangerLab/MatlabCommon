% Eli Bowen
% 5/7/2021
% copies the fields of the second struct into the first one
% INPUTS:
%   s1 - destination struct
%   s2 - source struct
%   collisionMethod - OPTIONAL (default = 'error') - method for handling fields that exist in both s1 and s2; must be one of 'error', 'donotoverwrite', 'overwrite'
% RETURNS:
%   s1 - destination struct with new fields
function [s1] = StructCopy (s1, s2, collisionMethod)
    validateattributes(s1, {'struct'}, {'nonempty','scalar'});
    validateattributes(s2, {'struct'}, {'nonempty','scalar'});
    if ~exist('collisionMethod', 'var') || isempty(collisionMethod)
        collisionMethod = 'error';
    end
    validateattributes(collisionMethod, {'char'}, {'nonempty','vector'});
    
    fields = fieldnames(s2);
    for i = 1:numel(fields)
        if isfield(s1, fields{i}) && strcmp(collisionMethod, 'error')
            error(['both structs have field ',fields{i}]);
        elseif ~isfield(s1, fields{i}) || strcmp(collisionMethod, 'overwrite')
            s1.(fields{i}) = s2.(fields{i});
        else
            assert(strcmp(collisionMethod, 'donotoverwrite'));
        end
    end
end