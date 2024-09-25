% Eli Bowen 9/2024
% returns true if the cell contains all nans
% using cellfun directly gets really complicated, so we need our own function here
function tf = IsCellAllNan(x)
    validateattributes(x, {'cell'}, {}, 1);
    tf = true;
    for i = 1 : numel(x)
        curr = x{i};
        if iscell(curr)
            tf = tf && IsCellAllNan(curr); % recurse
        else
            tf = tf && all(isnan(curr(:)));
        end
    end
    % tf = all(cellfun(@all, cellfun(@isnan, trnOneVsRest(:), UniformOutput=false)))
end