% Eli Bowen 2/2022
% INPUTS:
%   data - d x n (numeric)
%   k    - scalar (int-valued numeric)
% RETURNS:
%   data - d x n (numeric) if input is on gpu or sparse, so is output
%   idx  - k x n (numeric index 1 --> d), elements are sorted largest to smallest
function data = KWTA(data, k)
    validateattributes(data, {'numeric'}, {}, 1);
    validateattributes(k, {'numeric'}, {'nonempty','scalar','integer'}, 2);
    do_flip = false;
    if isvector(data) && size(data, 2) > size(data, 1)
        data = data'; % should be d x 1
        do_flip = true;
    end
    [~,n] = size(data);

    [~,idx] = maxk(data, k, 1); % idx is k x n
    data(:) = 0;
    for i = 1 : n
        data(idx(:,i),i) = 1;
    end

    if do_flip
        data = data'; % flip back
    end
end