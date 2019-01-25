function [errors] = errorMatrix(img, overlap, location, patchSize, ovSize)
% get image size
[Hin,Win,~] = size(img);
% initialize error matrix with 0's.
errors = zeros(Hin - patchSize, Win - patchSize);

% loop through all possible target block locations
for r = 1:Hin - patchSize
  for c = 1:Win - patchSize
    % target block starting index
    r_s = r;
    c_s = c;
    if strcmp(location, 'left')
      % keep full row width (patchSize)
      r_e = r_s + patchSize - 1;
      % keep overlapping column width (ovSize)
      c_e = c_s + ovSize - 1;
      
    elseif strcmp(location, 'top')
      % keep overlapping row width (ovSize)
      r_e = r_s + ovSize - 1;
      % keep full column width (patchSize)
      c_e = c_s + patchSize - 1;
    
    elseif strcmp(location, 'corner')
      % redundant intersecting region in the corner
      r_e = r_s + ovSize - 1;
      c_e = c_s + ovSize - 1;
    end
    
    % extract block from image
    target = img(r_s:r_e, c_s:c_e, :);
    % compute L2 norm error
    errors(r, c) = sum((overlap(:) - target(:)).^2);
  end
end

end

