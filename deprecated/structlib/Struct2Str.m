% Eli Bowen 12/1/2021
% should ONLY be used with structs containing short, numeric or char fields
% INPUTS:
%   s - struct
%   do_include_fieldnames - OPTIONAL scalar (logical) default = true
% RETURNS:
%   x - char
function x = Struct2Str(s, do_include_fieldnames)
    validateattributes(s, {'struct'}, {'nonempty','scalar'}, 1);
    if ~exist('do_include_fieldnames', 'var') || isempty(do_include_fieldnames)
        do_include_fieldnames = true;
    end

    x = '';
    fn = fieldnames(s);
    for i = 1 : numel(fn)
        if do_include_fieldnames
            x = [x,fn{i},'_',num2str(s.(fn{i}))];
        else
            x = [x,num2str(s.(fn{i}))];
        end
        if i < numel(fn)
            x = [x,'_'];
        end
    end
end