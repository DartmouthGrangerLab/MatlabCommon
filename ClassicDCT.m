% Classic_DCT - perform a block DCT for an image
% ASSUMES blocks are 8x8
function transform_image = ClassicDCT(image)
    assert(isfloat(image));
    assert(all(mod(size(image), 8) == 0));

    C = cast(Classic_DCT_Block(8), 'like', image);

    transform_image = zeros(size(image, 1), size(image, 2), 'like', image);
    for n = 0 : size(image, 2)/8 - 1
        for m = 0 : size(image, 1)/8 - 1
            transform_image(m*8+(1:8),n*8+(1:8)) = C * image(m*8+(1:8),n*8+(1:8)) * C';
        end
    end
end


% Classic_DCT_Block - implementation of a 2D DCT
function C = Classic_DCT_Block(N)
    cols = 0:N-1;
    C = zeros(N, N);
    for row = 0 : N-1
        C(row+1,:) = (2.*cols + 1) .* row;
    end
    C = cos(C .* (pi/2/N)) ./ sqrt(N);
    C(2:end,:) = C(2:end,:) .* sqrt(2); % no sqrt(2) for row=0
end