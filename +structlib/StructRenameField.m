% Eli Bowen 12/17/2020
% rename a field in a struct or cell array of structs
% INPUTS:
%   s       - struct to modify (returned), or cell array of structs all of which should be modified
%   oldName - (char) old field name
%   newName - (char) new field name
% RETURNs:
%   s
function s = StructRenameField(s, oldName, newName)
    validateattributes(s, {'struct','cell'}, {'nonempty'}, 1);
    validateattributes(oldName, {'char'}, {'nonempty'}, 2);
    validateattributes(newName, {'char'}, {'nonempty'}, 3);

    if isstruct(s)
        if numel(s) == 1 % special case for efficiency
            s = Helper(s, oldName, newName);
        else
            for i = 1 : numel(s) % for the record, I hate non-scalar structs
                temp(i) = Helper(s(i), oldName, newName);
            end
            s = temp;
        end
    else % cell
        for i = 1 : numel(s)
            if numel(s{i}) == 1 % special case for efficiency
                s{i} = Helper(s{i}, oldName, newName);
            else
                for j = 1:numel(s{i}) % for the record, I hate non-scalar structs
                    temp(j) = Helper(s{i}(j), oldName, newName);
                end
                s{i} = temp;
            end
        end
    end
end


function s = Helper(s, oldName, newName)
    assert(isfield(s, oldName));
    assert(~isfield(s, newName));

    s.(newName) = s.(oldName);
    s = rmfield(s, oldName);
end