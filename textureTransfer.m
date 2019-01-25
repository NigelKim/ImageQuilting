function [output] = textureTransfer(tex, tar, patch_h, patch_w, ov_h, ov_w, tolerance,alpha,numiters)
o_patch_h = patch_h;
o_patch_w = patch_w;
o_ov_h = ov_h;
o_ov_w = ov_w;
for i=1:numiters
    tic;
    % get texture size
    [tex_h, tex_w, tex_c] = size(tex);
    fprintf('texture size: %d,%d,%d\n',tex_h,tex_w,tex_c);
    % get target size
    [tar_h, tar_w, tar_c] = size(tar);
    fprintf('target size: %d,%d,%d\n',tar_h,tar_w,tar_c);
    % initialize output
    output = double(zeros(tar_h, tar_w, 3));
    [out_h, out_w, ~] = size(output);
    % RGB to Gray if we our correspondance maps to be luminance(image
    % intensity)
    tex_corr = double(rgb2gray(uint8(tex)));
    tar_corr = double(rgb2gray(uint8(tar)));

    % initialize patchsize and overlap region sizes
    patchSize_h = patch_h;
    patchSize_w = patch_w;
    ovSize_h = ov_h;
    ovSize_w = ov_w;
    for r = 1:ceil(out_h/patchSize_h)
      % column
      for c = 1:ceil(out_w/patchSize_w)
        % defining patch position index boundaries
        if r==ceil(out_h/patchSize_h)
            ovSize_h = ceil(rem(out_h,patchSize_h)/6);
            if rem(out_h,patchSize_h)==0
                ovSize_h = ov_h;
            end
        end
        r_s = 1+(r-1)*(patchSize_h-ovSize_h);
        r_e = r_s+patchSize_h-1;
        if r==ceil(out_h/patchSize_h)
            patchSize_h = rem(out_h,patchSize_h);
            if patchSize_h==0
                patchSize_h = patch_h;
            end
            r_e = r_s+patchSize_h-1; 
        end

        if c==ceil(out_w/patchSize_w)
            ovSize_w = ceil(rem(out_h,patchSize_h)/6);
            if rem(out_w,patchSize_w)==0
                ovSize_w = ov_w;
            end
        end
        c_s = 1+(c-1)*(patchSize_w-ovSize_w);
        c_e = c_s+patchSize_w-1;
        if c==ceil(out_w/patchSize_w)
            patchSize_w = rem(out_w,patchSize_w);
            if patchSize_w==0
                patchSize_w = patch_w;
            end
            c_e = c_s+patchSize_w-1;
        end

        % Initialize errors for the first case
        errors = zeros(tex_h - patchSize_h, tex_w - patchSize_w);

        if r==1 && c==1
          % Starting from top-left. Pick one randomly and initialize patch.
          % Cannot pick index from the entire image: taking into consideration the
          % patch size to be added later.
          r_ix = randi(tex_h-patchSize_h);
          c_ix = randi(tex_w-patchSize_w);
          patch = tex(r_ix:r_ix+patchSize_h-1, c_ix:c_ix+patchSize_w-1, :);
          output(r_s:r_e, c_s:c_e, :) = patch;
        elseif r==1 && c~=1
          % first row only has left overlaps.
          % c_s is at the left overlap start position
          % overlap: overlap region from the previous block that will be used
          % to find a matching block
          overlap = output(r_s:r_e, c_s:c_s + ovSize_w - 1, :);
          if i>1
            prevov = prev(r_s:r_e, c_s:c_s + ovSize_w - 1, :);
          else
            prevov = overlap;
          end
          errors = errorMatrixModified(tex, tex_corr, tar_corr, r, c, alpha, overlap,prevov, 'left', patchSize_h, patchSize_w, ovSize_h, ovSize_w, true);
        elseif r~=1 && c==1
          % first column only has top overlaps.
          % r_s is at the top overlap start position
          overlap = output(r_s:r_s + ovSize_h - 1, c_s:c_e, :);
          if i>1
            prevov = prev(r_s:r_s + ovSize_h - 1, c_s:c_e, :);
          else
            prevov = overlap;
          end
          errors = errorMatrixModified(tex, tex_corr, tar_corr, r, c, alpha, overlap,prevov, 'top', patchSize_h, patchSize_w, ovSize_h, ovSize_w, true);
        else
          % if not first row and first column, both top and left overlaps.
          leftOverlap = output(r_s:r_e, c_s:c_s + ovSize_w - 1, :);
          topOverlap = output(r_s:r_s + ovSize_h - 1, c_s:c_e, :);
          if i>1
              prevovl = prev(r_s:r_e, c_s:c_s + ovSize_w - 1, :);
              prevovt = prev(r_s:r_s + ovSize_h - 1, c_s:c_e, :);
          else
              prevovl = leftOverlap;
              prevovt = topOverlap;
          end
          errors = errorMatrixModified(tex, tex_corr, tar_corr, r, c, alpha, leftOverlap,prevovl, 'left', patchSize_h, patchSize_w, ovSize_h, ovSize_w, true) + errorMatrixModified(tex, tex_corr, tar_corr, r, c, alpha, topOverlap, prevovt,'top', patchSize_h, patchSize_w, ovSize_h, ovSize_w, false);
          % subtract redundant intersecting region in the corner once
          cornerOverlap = output(r_s:r_s + ovSize_h - 1, c_s:c_s + ovSize_w - 1, :);
          if i>1
            prevovc = prev(r_s:r_s + ovSize_h - 1, c_s:c_s + ovSize_w - 1, :);
          else
            prevovc = cornerOverlap;
          end
          errors = errors - errorMatrixModified(tex, tex_corr, tar_corr, r, c, alpha, cornerOverlap, prevovc,'corner', patchSize_h, patchSize_w, ovSize_h, ovSize_w, false);
        end

        %   find set of blocks that satisfy the overlap constraints within the
        %   error tolerance
        satisfied = find(errors(:)<=(1+tolerance)*min(errors(:)));
        %   pick one block randomly
        randNum = randi(length(satisfied));
        selected_ix = satisfied(randNum);
        % convert selected_ix into grid location coordinates in 
        % (Hin - patchSize) by (Win - patchSize) matrix
        [new_r, new_c] = ind2sub(size(errors), selected_ix);

        % initialize boundary. cut will be labeled 0, new-side of the cut will
        % be labeled 1, old-side of the cut will be labeled -1.
        boundary = ones(patchSize_h, patchSize_w);

        % Find minimum cost path and make a boundary cut
        if r~=1
          % top overlap
          ov_new = tex(new_r:new_r+ovSize_h - 1, new_c:new_c+patchSize_w - 1, :);
          ov_prev = output(r_s:r_s+ovSize_h - 1, c_s:c_e, :);
          cut = minCut(ov_new, ov_prev, 'hor');
          % only consider boundary(labeled 0) and new kept ov region(labeled 1)
          newmask =(cut>=0);
          boundary(1:ovSize_h, 1:patchSize_w) = newmask;
        end
        if c~=1
          % left overlap
          ov_new = tex(new_r:new_r+patchSize_h-1, new_c:new_c+ovSize_w-1, :);
          ov_prev = output(r_s:r_e, c_s:c_s+ovSize_w-1, :);
          cut = minCut(ov_new, ov_prev, 'ver');
          % only consider boundary(labeled 0) and new kept ov region(labeled 1)
          newmask = (cut>=0);
          boundary(1:patchSize_h, 1:ovSize_w) = boundary(1:patchSize_h, 1:ovSize_w).*newmask;
        end

        % converting to 3 channels
        boundary = repmat(boundary, 1, 1, 3);
        % assigning to original patch's overlapping region up to the boundary
        leftmask = (boundary<=0);
        output(r_s:r_e,c_s:c_e,:) = output(r_s:r_e,c_s:c_e,:).*leftmask;
        % assigning to the newly added patch region at the right side of the
        % boundary
        rightmask = (boundary==1);
        output(r_s:r_e,c_s:c_e,:) = output(r_s:r_e,c_s:c_e,:)+tex(new_r:new_r+patchSize_h-1,new_c:new_c+patchSize_w-1,:).*rightmask;
        % restoring patchsize and ovsize
        patchSize_w = patch_w;
        ovSize_w = ov_w;
      end
      % show output as the algorithm goes ----- ERASE LATER!!
%       imshow(uint8(output));
%       drawnow();
      % restoring patchsize and ovsize
      patchSize_h = patch_h;
      ovSize_h = ov_h;
    end
    % imshow(uint8(output(1:(patch_h-ov_h)*floor(out_h/patchSize_h)+ov_h,1:(patch_w-ov_w)*floor(out_w/patchSize_w)+ov_w,:)));
%     prevTar = output(1:(patch_h-ov_h)*floor(out_h/patchSize_h)+ov_h,1:(patch_w-ov_w)*floor(out_w/patchSize_w)+ov_w,:);
    prev = output;%(1:(o_patch_h-o_ov_h)*floor(out_h/o_patch_h)+o_ov_h,1:(o_patch_w-o_ov_w)*floor(out_w/o_patch_w)+o_ov_w,:);
    figure;
    imshow(uint8(prev(1:(o_patch_h-o_ov_h)*floor(out_h/o_patch_h)+o_ov_h,1:(o_patch_w-o_ov_w)*floor(out_w/o_patch_w)+o_ov_w,:)));
    patch_h = floor(patch_h/3);
    patch_w = floor(patch_w/3);
    ov_h = floor(patch_h/6);
    ov_w = floor(patch_w/6);
    alpha = 0.8*(i-1/(numiters-1))+0.1;
    toc;
end
output = uint8(tar(1:(o_patch_h-o_ov_h)*floor(out_h/o_patch_h)+o_ov_h,1:(o_patch_w-o_ov_w)*floor(out_w/o_patch_w)+o_ov_w,:));

end
