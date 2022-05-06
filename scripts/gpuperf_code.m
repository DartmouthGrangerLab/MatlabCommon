
N = 20000;

disp('mul cpu');
A = double(rand(N, N));
B = double(rand(N, N));
timeit(@()A*B)
A = single(rand(N, N));
B = single(rand(N, N));
timeit(@()A*B)

disp('mul gpu');
A = gpuArray(double(rand(N, N)));
B = gpuArray(double(rand(N, N)));
gputimeit(@()A*B)
A = gpuArray(single(rand(N, N)));
B = gpuArray(single(rand(N, N)));
gputimeit(@()A*B)

disp('pairwise mul cpu');
A = double(rand(1, N*N));
B = double(rand(1, N*N));
gputimeit(@()A.*B)
A = single(rand(1, N*N));
B = single(rand(1, N*N));
gputimeit(@()A.*B)
A = uint16(randi(2^16-1, 1, N*N));
B = uint16(randi(2^16-1, 1, N*N));
gputimeit(@()A.*B)
A = uint8(randi(2^8-1, 1, N*N));
B = uint8(randi(2^8-1, 1, N*N));
gputimeit(@()A.*B)

disp('pairwise mul gpu');
A = gpuArray(double(rand(1, N*N)));
B = gpuArray(double(rand(1, N*N)));
gputimeit(@()A.*B)
A = gpuArray(single(rand(1, N*N)));
B = gpuArray(single(rand(1, N*N)));
gputimeit(@()A.*B)
A = gpuArray(uint16(randi(2^16-1, 1, N*N)));
B = gpuArray(uint16(randi(2^16-1, 1, N*N)));
gputimeit(@()A.*B)
A = gpuArray(uint8(randi(2^8-1, 1, N*N)));
B = gpuArray(uint8(randi(2^8-1, 1, N*N)));
gputimeit(@()A.*B)

disp('idx gpu');
A = gpuArray(double(rand(1, N*N)));
B = gpuArray(double(randi(N, 1, N*N)));
gputimeit(@()A(B))
A = gpuArray(single(rand(1, N*N)));
B = gpuArray(single(randi(N, 1, N*N)));
gputimeit(@()A(B))
A = gpuArray(uint16(randi(2^16-1, 1, N*N)));
B = gpuArray(single(randi(N, 1, N*N)));
gputimeit(@()A(B))
A = gpuArray(uint8(randi(2^8-1, 1, N*N)));
B = gpuArray(single(randi(N, 1, N*N)));
gputimeit(@()A(B))
A = gpuArray(uint8(randi(2^8-1, 1, N*N)));
B = gpuArray(uint16(randi(N, 1, N*N)));
gputimeit(@()A(B))