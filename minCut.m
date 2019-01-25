function [ bestcut ] = minCut( ov_new, ov_prev, location )

% get error surface
E = sum((ov_new - ov_prev).^2, 3);
if location=='hor'
  E = E';
end
[err_h, err_w, ~] = size(E);
%% Dynamic Programming, as stated in Efros and Freeman 2001.
% Initialize DP table
table = zeros(err_h, err_w);
% Initialize starting points(first row)
table(1, :) = E(1, :);
% Compute table 
for r = 2:err_h
  for c = 1:err_w
    % construct a set of 3 possible previous paths(coming from top, top-left, or top-right)
    % top
    paths = table(r-1, c);
    % boundary condition
    if c ~= 1
      % top-left
      paths = [paths table(r-1, c-1)];
    end
    % boundary condition
    if c ~= err_w
      % top-right
      paths = [paths table(r-1, c+1)];
    end
    % find minimum path among 3 possible choices, and update the table 
    % by adding the current error value and the minimum cost path to reach
    % the current position
    table(r, c) = E(r, c) + min(paths);
  end
end

% Trace back to find the path of the best cut
bestcut = ones(err_h, err_w);
% minimum value of the last row in E indicates the end (which will be the
% start for backtracking)
[~, start_c] = min(E(err_h, 1:err_w));
% assign 0 to the minium value of the last row in E (boundary)
bestcut(err_h, start_c) = 0;
% assign 1 to the kept region (new)
bestcut(err_h, start_c+1:err_w) = 1;
% assign -1 to the discarded region (included in prev)
bestcut(err_h, 1:start_c-1) = -1;

% tracing back
% visiting row backwards
for r = err_h-1:-1:1 
  % visit all columns
  for c = 1:err_w 
    % checking top-right
    if start_c < err_w
      % if top-right is the min of the top 3 neighbors(top, top-left, top-right)
      if E(r, start_c+1) == min(E(r, max(start_c-1, 1):start_c+1))
        % assign new starting point(connecting path)
        start_c = start_c + 1;
      end
    end
    
    % checking top-left
    if start_c > 1
      % if top-left is the min of the top 3 neighbors(top, top-left, top-right)
      if E(r, start_c-1) == min(E(r, start_c-1:min(start_c+1, err_w)))
        start_c = start_c - 1;
      end
    end
    
    % if neither top-left or top-right chosen, start_c = start_c
    % assign 0 to the minium value of the next last row in E (boundary)
    bestcut(r, start_c) = 0;
    % assign 1 to the kept region (new)
    bestcut(r, start_c+1:err_w) = 1;
    % assign -1 to the discarded region (included in prev)
    bestcut(r, 1:start_c-1) = -1;
  end
end
if location=='hor'
  bestcut = bestcut';
end

end

