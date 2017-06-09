function w = fmin_sgd(func, w0, iters, stepSize0)
w = w0;
for iter = 1:iters
    [f,g] = func(w, iter);
    stepSize = stepSize0 * min(1000.0/double(iter), 1.0);
    fprintf('Iter = %d of %d (fsub = %f) (lr = %f)\n',iter, iters, f, stepSize);
    w = w - stepSize*g;
end
