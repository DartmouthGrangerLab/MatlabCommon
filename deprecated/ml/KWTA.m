% deprecated (instead, see ml package)
function data = KWTA(data, k)
    validateattributes(data, {'numeric'}, {}, 1);
    validateattributes(k, {'numeric'}, {'nonempty','integer'}, 2);
    do_flip = false;
    if isvector(data) && size(data, 2) > size(data, 1)
        data = data'; % should be d x 1
        do_flip = true;
    end
    [~,n] = size(data);

    if isscalar(k)
        [~,idx] = maxk(data, k, 1); % idx is k x n
        data(:) = 0;
        for i = 1 : n
            data(idx(:,i),i) = 1;
        end
    else
        [~,idx] = maxk(data, max(k), 1); % idx is k x n, sorted from max downwards
        data(:) = 0;
        for i = 1 : n
            data(idx(1:k(i),i),i) = 1;
        end
    end

    if do_flip
        data = data'; % flip back
    end
end