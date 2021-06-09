function img_out = lapBlend(src, masks, level, batch)
%lapBlend - Laplacian image blending function
%
% Syntax: img_out = lapBlend(src, mask, level, batch)
%
% Long description
if nargin < 2
    error ("Too few input arguments. At least 2.")
elseif nargin < 3
    level = 4;
    batch = 1;
elseif nargin < 4
    batch = 1;
elseif nargin>4
    error("Too many input arguments.");
end
assert(length(src) == length(masks), ...
"Number of source images is different to the number of masks");

img_num = length(src);
mid = ceil(img_num/batch/2);
mid_img = cell(2*batch, 1);
mid_mask = cell(2*batch, 1);

if batch == 1
    [img_out, ~] = lapMultiBlend(src, masks, level);
else
    both_src = cell(2*mid, 1);
    both_src(1:mid) = src(1:mid);
    both_src(mid+1:end) = src((2*batch-1)*mid+1:end);
    both_masks = cell(2*mid, 1);
    both_masks(1:mid) = masks(1:mid);
    both_masks(mid+1:end) = masks((2*batch-1)*mid+1:end);


    [mid_img{end}, mid_mask{end}] = lapMultiBlend(both_src, both_masks, level);
    for i=1:2*batch-1
        end_idx = min((i+1)*mid, img_num);
        [mid_img{i}, mid_mask{i}] = lapMultiBlend(src((i-1)*mid+1:end_idx), masks((i-1)*mid+1:end_idx), level);
    end
%     [img_out,~] = lapMultiBlend(mid_img, mid_mask);
%     img_out = lapBlend(mid_img, mid_mask);
    img_out = linearBlend(mid_img, mid_mask);
    img_out(img_out==0)= NaN;
end
end
    

  

