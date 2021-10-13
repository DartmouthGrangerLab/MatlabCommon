label = randi(2, 100000, 1);
label(label==2) = -1;
data = rand(100000, 1000);
t=tic();
data = sparse([data,ones(100000, 1)]);
toc(t)
t=tic();
for i = 1:10
    model = train(label, data, '-q -s 2 -c 1 -n 8 -w1 1.1111 -w2 10');
end
toc(t)
t=tic();
for i = 1:10
    model = train(label, data, '-q -s 2 -c 1 -m 8 -w1 1.1111 -w2 10');
end
toc(t)
t=tic();
for i = 1:10
    model = train(label, data, '-q -s 2 -c 1 -m 1 -w1 1.1111 -w2 10');
end
toc(t)
t=tic();
for i = 1:10
    model = train(label, data, '-s 2 -m 8');
end
toc(t)
t=tic();
for i = 1:10
    model = train(label, data, '-s 0 -m 8');
end
toc(t)

[label1,data1] = libsvmread('../heart_scale');