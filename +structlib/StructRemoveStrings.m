% Eli Bowen 3/2025
function s = StructRemoveStrings(s)
    validateattributes(s, {'struct'}, {'nonempty'}, 1);

    fn = fieldnames(s);
    for i = 1 : numel(fn)
        if isstruct(s.(fn{i}))
            s.(fn{i}) = structlib.StructRemoveStrings(s.(fn{i}));
        elseif isstring(s.(fn{i}))
            if numel(s.(fn{i})) == 1
                s.(fn{i}) = char(s.(fn{i}));
            else
                temp = cell(numel(s.(fn{i})), 1);
                for j = 1 : numel(s.(fn{i}))
                    temp{j} = char(s.(fn{i})(j));
                end
                s.(fn{i}) = temp;
            end
        end
    end
end