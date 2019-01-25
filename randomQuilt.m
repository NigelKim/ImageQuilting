function [output] = randomQuilt(img, patchSize, numPatchSide)
[Hin,Win,Cin] = size(img);
fprintf('input size: %d,%d,%d\n',Hin,Win,Cin);

% quilted in steps of (patchSize-ovSize)
out_size = numPatchSide*patchSize;
% init output image
output = double(zeros(out_size,out_size,3));
[Hout,Wout,Cout] = size(output);
fprintf('output size: %d,%d,%d\n',Hout,Wout,Cout);

% row
for r = 1:numPatchSide
  % column
  for c = 1:numPatchSide
    r_s = 1+(r-1)*patchSize;
    r_e = r_s+patchSize-1;
    c_s = 1+(c-1)*patchSize;
    c_e = c_s+patchSize-1;
    
    r_ix = randi(Hin-patchSize+1);
    c_ix = randi(Win-patchSize+1);
    patch = img(r_ix:r_ix+patchSize-1, c_ix:c_ix+patchSize-1, :);
    % alpha blending edges
    if r~=1
        newEdge = (0.5)*prevEdge_top+(0.5)*patch(patchSize,1:patchSize,:);
        patch(patchSize,1:patchSize,:) = newEdge;
    end
    if c~=1
        newEdge = (0.5)*prevEdge_side+(0.5)*patch(1:patchSize,patchSize,:);
        patch(1:patchSize,patchSize,:) = newEdge;
    end
    prevEdge_top = patch(patchSize,1:patchSize,:);
    prevEdge_side = patch(1:patchSize,patchSize,:);
    output(r_s:r_e, c_s:c_e, :) = patch;
  end
end
output = uint8(output);
end
