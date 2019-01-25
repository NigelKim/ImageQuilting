%  main

% Initialize parameters
patchSize = 48;
numPatchSide = 10; %experimented with 15(too slow). changing to 10(half time)
% overlap region size and tolerance set from Efros and Freeman 2001
ovSize = floor(patchSize/6);
tolerance = 0.1;

% get image
% Regular Texture
%   img = double(imread('inputs/brick2.jpg'));
  img = double(imread('inputs/structured_tex.jpg'));
% Near-Regular Texture
% img = double(imread('inputs/brick.jpg'));
% img = double(imread('inputs/weave.jpg'));

% Irregular Texture
% img = double(imread('inputs/berry.jpg'));
% img = double(imread('inputs/olive.png'));

% Near-Stochastic Texture
% img = double(imread('inputs/fire.jpg'));
% img = double(imread('inputs/caustics.png'));

% Stochastic Texture
% img = double(imread('inputs/sand.jpeg'));
% img = double(imread('inputs/stone.jpg'));

tic;
%% Xu et al.[2]
% output = randomQuilt(img,patchSize,numPatchSide);
%% Overlap Constrained
output = imageQuiltNoCut(img, patchSize, numPatchSide, ovSize, tolerance);
%% Overlap with Minimum Error Boundary Cut
% output = imageQuilt(img, patchSize, numPatchSide, ovSize, tolerance);
toc;
figure;
imshow(output);

%% Texture Transfer
% Parameters
% patch_h = 18;
% patch_w = 18;
% ov_h = floor(patch_h/6);
% ov_w = floor(patch_w/6);
% tolerance = 0.1;
% alpha = 0.6;
% N = 2;
% 
% % get texture image
% % tex = double(imread('inputs/starryNight_tiny.png'));
% % tex = double(imread('inputs/wool_tex2.jpg'));
% % tex = double(imread('inputs/monet_tex5.jpg'));
% % tex = double(imread('inputs/acrylic1.jpeg'));
% tex = double(imread('inputs/yogurt.jpg'));
% % get target image
% % tar = double(imread('inputs/arch2.png'));
% % tar = double(imread('inputs/davidhat.jpg'));
% % tar = double(imread('inputs/monet_giverny4.jpg'));
% % tar = double(imread('inputs/scenery2.jpg'));
% tar = double(imread('inputs/david2.jpg'));
% output = textureTransfer(tex, tar, patch_h, patch_w, ov_h, ov_w, tolerance,alpha,N);
% figure;
% imshow(output);




