% Eli Bowen 9/2024
% returns true if the cell contains all nans
% using cellfun directly gets really complicated, so we need our own function here
function tf = IsCellAllZero(x)
    validateattributes(x, {'cell'}, {}, 1);
    tf = true;
    for i = 1 : numel(x)
        curr = x{i};
        if iscell(curr)
            tf = tf && IsCellAllZero(curr); % recurse
        else
            tf = tf && all(curr(:) == 0);
        end
    end
end