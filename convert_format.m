function [X, Y] = convert_format(X0, Y0)
  nNodes = 1000;
  num_samples = size(X0, 1);
  Y = zeros(num_samples, nNodes, 'int32');
  X = zeros(num_samples, nNodes);
  INDEX = int32(X0(:, 1:5));
  PROP = double(X0(:, 6:end));
  for i = 1:num_samples
    Y(i, Y0(i)+1) = 1;
    for j = 1:5
      X(i, INDEX(i, j)+1) = PROP(i, j);
    end
  end
  Y = Y + 1;
end
