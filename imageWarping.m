function [warped, mask] = imageWarping(ori, T, x, y)
%imageWarping - warp image using T and projection to meshgrid x, y
%
% Syntax: warped = imageWarping(ori, T, x, y)
%
% Long description
% Input: 
% ori : original image
% T: 3*3 Transformer
% x, y: meshgrid
    
H = inv(T);

z_ = H(3,1) * x + H(3,2) * y + H(3,3) ;
x_ = (H(1,1) * x + H(1,2) * y + H(1,3)) ./ z_ ;
y_ = (H(2,1) * x + H(2,2) * y + H(2,3)) ./ z_ ;
warped = (vl_imwbackward(im2double(ori), x_,y_));
mask = ~isnan(warped(:,:,1));
warped(isnan(warped)) = 0;
clear z_ x_ y_
end