% Eli Bowen 5/7/2021
% copies the fields of the second struct into the first one
% INPUTS:
%   s1 - scalar (struct) destination
%   s2 - scalar (struct) source
%   collisionMethod - OPTIONAL (default = 'error') - method for handling fields that exist in both s1 and s2; must be one of 'error', 'donotoverwrite', 'overwrite'
% RETURNS:
%   s1 - destination struct with new fields
function s1 = StructCopy(s1, s2, collisionMethod)
    validateattributes(s1, {'struct'}, {'nonempty','scalar'}, 1);
    validateattributes(s2, {'struct'}, {'nonempty','scalar'}, 2);
    if ~exist('collisionMethod', 'var') || isempty(collisionMethod)
        collisionMethod = 'error';
    end
    validateattributes(collisionMethod, {'char'}, {'nonempty','vector'});

    fn = fieldnames(s2);
    for i = 1 : numel(fn)
        if isfield(s1, fn{i}) && strcmp(collisionMethod, 'error')
            error(['both structs have field ',fn{i}]);
        elseif ~isfield(s1, fn{i}) || strcmp(collisionMethod, 'overwrite')
            s1.(fn{i}) = s2.(fn{i});
        else
            assert(strcmp(collisionMethod, 'donotoverwrite'));
        end
    end
end