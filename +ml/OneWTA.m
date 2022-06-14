% Eli Bowen 2/2022
% INPUTS
%   data - d x n (numeric)
% RETURNS
%   data - d x n (numeric) if input is on gpu or sparse, so is output
% see also ml.KWTA
function data = OneWTA(data)
    validateattributes(data, {'numeric'}, {}, 1);
    do_flip = false;
    if isvector(data) && size(data, 2) > size(data, 1)
        data = data'; % should be d x 1
        do_flip = true;
    end
    [~,n] = size(data);

    [~,idx] = max(data, [], 1); % idx is 1 x n
    data(:) = 0;
    for i = 1 : n
        data(idx(i),i) = 1;
    end

    if do_flip
        data = data'; % flip back
    end
end