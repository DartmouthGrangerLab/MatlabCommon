% perform a block inverse DCT for an image
% ASSUMES blocks are 8x8
function restored_image = Classic_DCT_Inverse(transform_image)
    assert(isfloat(transform_image));
    assert(all(mod(size(transform_image), 8) == 0));
    
    C = cast(pdip_inv_dct2(8), 'like', transform_image);

    restored_image = zeros(size(transform_image), 'like', transform_image);
    for n = 0 : size(transform_image,2)/8 - 1
        for m = 0 : size(transform_image,1)/8 - 1
            restored_image(m*8+(1:8),n*8+(1:8)) = C' * transform_image(m*8+(1:8),n*8+(1:8)) * C;
        end
    end
end


% pdip_inv_dct2 - implementation of an inverse 2 Dimensional DCT
function C = pdip_inv_dct2(N)
    cols = 0:N-1;
    C = zeros(N, N);
    for row = 0 : N-1
        C(row+1,:) = (2.*cols + 1) .* row;
    end
    C = cos(C .* (pi/2/N)) ./ sqrt(N);
    C(2:end,:) = C(2:end,:) .* sqrt(2); % no sqrt(2) for row=0
end