function [output] = imageQuiltNoCut(img, patchSize, numPatchSide, ovSize, tolerance)
[Hin,Win,Cin] = size(img);
fprintf('input size: %d,%d,%d\n',Hin,Win,Cin);

% quilted in steps of (patchSize-ovSize)
out_size = numPatchSide*(patchSize-ovSize)+ovSize;
% init output image
output = double(zeros(out_size,out_size,3));
[Hout,Wout,Cout] = size(output);
fprintf('output size: %d,%d,%d\n',Hout,Wout,Cout);

% row
for r = 1:numPatchSide
  % column
  for c = 1:numPatchSide
    % If i == 1 then we're at the top row, so check error above
    %    j == 1           ""     left col, so check error left
    %
    % defining patch position index sboundaries
    r_s = 1+(r-1)*(patchSize-ovSize);
    r_e = r_s+patchSize-1;
    c_s = 1+(c-1)*(patchSize-ovSize);
    c_e = c_s+patchSize-1;
    
    % Initialize errors for the first case
    errors = zeros(Hin - patchSize, Win - patchSize);
    
    if r==1 && c==1
      % Starting from top-left. Pick one randomly and initialize patch.
      % Cannot pick index from the entire image: taking into consideration the
      % patch size to be added later.
      r_ix = randi(Hin-patchSize+1);
      c_ix = randi(Win-patchSize+1);
      patch = img(r_ix:r_ix+patchSize-1, c_ix:c_ix+patchSize-1, :);
      output(r_s:r_e, c_s:c_e, :) = patch;
    elseif r==1 && c~=1
      % first row only has left overlaps.
      % c_s is at the left overlap start position
      % overlap: overlap region from the previous block that will be used
      % to find a matching block
      overlap = output(r_s:r_e, c_s:c_s + ovSize - 1, :);
      errors = errorMatrix(img, overlap, 'left', patchSize, ovSize);
    elseif r~=1 && c==1
      % first column only has top overlaps.
      % r_s is at the top overlap start position
      overlap = output(r_s:r_s + ovSize - 1, c_s:c_e, :);
      errors = errorMatrix(img, overlap, 'top', patchSize, ovSize);
    else
      % if not first row and first column, both top and left overlaps.
      leftOverlap = output(r_s:r_e, c_s:c_s + ovSize - 1, :);
      topOverlap = output(r_s:r_s + ovSize - 1, c_s:c_e, :);
      errors = errorMatrix(img, leftOverlap, 'left', patchSize, ovSize) + errorMatrix(img, topOverlap, 'top', patchSize, ovSize);
      % subtract redundant intersecting region in the corner once
      cornerOverlap = output(r_s:r_s + ovSize - 1, c_s:c_s + ovSize - 1, :);
      errors = errors - errorMatrix(img, cornerOverlap, 'corner', patchSize, ovSize);
    end
    
    %   find set of blocks that satisfy the overlap constraints within the
    %   error tolerance
    satisfied = find(errors(:) <= (1 + tolerance)*min(errors(:)));
    %   pick one block randomly
    randNum = randi(length(satisfied));
    selected_ix = satisfied(randNum);
    % convert selected_ix into grid location coordinates in 
    % (Hin - patchSize) by (Win - patchSize) matrix
    [new_r, new_c] = ind2sub(size(errors), selected_ix);

    output(r_s:r_e, c_s:c_e, :) = img(new_r:new_r + patchSize - 1, new_c:new_c + patchSize - 1, :);
  end
end
output = uint8(output);
end
