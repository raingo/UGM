function w = fmin_sgd(func, w0, iters, stepSize0)
  w = w0;
  tic;
  for iter = 1:iters
    [f,g] = func(w, iter);
    if any(isnan(g))
      fprintf('%d\n', iter);
      error('NaN found');
    end
    iter = double(iter);
    stepSize = stepSize0 * min(1000.0/iter, 1.0);
    if mod(iter, 10) == 0 || iter == 1
      eta = toc / iter * (iters - iter);
      fprintf('Iter = %d of %d (fsub = %.3g) (lr = %.3g) (eta = %.3f)\n',iter, iters, f, stepSize, eta);
    end
    w = w - stepSize*g;
  end
