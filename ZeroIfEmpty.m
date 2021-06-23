% Eli Bowen
% 6/18/2021
% if input is empty, returns a 0
% useful shortcut for e.g. "x(2,3) = data", which errors if data is empty
% preserves datatype
function [data] = ZeroIfEmpty (data)
    if isempty(data)
        data = cast(0, 'like', data);
    end % else leave unchanged
end