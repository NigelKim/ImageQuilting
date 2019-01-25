function [errors] = errorMatrixModified(tex, tex_corr, tar_corr, row, column, alpha, overlap,prevov, location, patchSize_h, patchSize_w, ovsize_h, ovsize_w, comparePrev)
% get texture size
[tex_h, tex_w, ~] = size(tex);
% initialize error matrix with 0's.
errors = zeros(tex_h - patchSize_h, tex_w - patchSize_w);

% loop through all possible target block locations
for r = 1:tex_h - patchSize_h
  for c = 1:tex_w - patchSize_w
    r_s = r; 
    c_s = c;
    if strcmp(location, 'left')
      % keep full row width (patchSize)
      r_e = r_s + patchSize_h - 1;
      % keep overlapping column width (ovSize)
      c_e = c_s + ovsize_w - 1;
    elseif strcmp(location, 'top')
      % keep overlapping row width (ovSize)
      r_e = r_s + ovsize_h - 1;
      % keep full column width (patchSize)
      c_e = c_s + patchSize_w - 1;
    elseif strcmp(location, 'corner')
      % redundant intersecting region in the corner
      r_e = r_s + ovsize_h - 1;
      c_e = c_s + ovsize_w - 1;
    end
    
    % extract block from image
    block = tex(r_s:r_e, c_s:c_e, :);
    % match 1: block matched with its neighbor blocks on the overlap
    % regions
    % compute L2 norm error
    match_1 = sum((overlap(:) - block(:)).^2);
    % block matched with whatever was synthesized at this block in
    % the previous iteration
%     compute L2 norm error
    match_1 = match_1 + sum((overlap(:) - prevov(:)).^2);
    
    % match 2: L2 norm on correspondance map
    match_2 = 0;
    if comparePrev
      tar_block = tar_corr((row-1)*patchSize_h + 1:row*patchSize_h, (column-1)*patchSize_w + 1:column*patchSize_w);
      tex_block = tex_corr(r_s:r_s+patchSize_h - 1, c_s:c_s+patchSize_w - 1, :);
      % compute L2 norm error
      match_2 = sum(tex_block(:) - tar_block(:)).^2;
    end    
    
    % Calculate the error for the block
    errors(r,c) = alpha*match_1+(1-alpha)*match_2;
  end
end

end

