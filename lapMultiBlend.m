function [img_out, mask] = lapMultiBlend(src, masks, level)
%lapMultiBlend - Laplacian image blending for images
%
% Syntax: img_out = lapMultiBlend(src, masks, levels)
%
% Long description
% Input:
% src: source images(warped)
% masks: blend masks of images
% level: level of Gaussian and Laplacian 
% Output:
% img_out: blending result
%
%

if nargin < 2
    error ("Too few input arguments. At least 2.")
elseif nargin < 3
    level = 4;
elseif nargin>3
    error("Too many input arguments.");
end
assert(length(src) == length(masks), ...
"Number of source images is different to the number of masks");

img_num = length(src);
levels = mat2cell(ones(img_num,1)*level, ones(1,img_num));

%% Build Laplacian pyramids
fprintf("Build Laplacian pyramids...");
[lap_pyrs, peak] = cellfun(@buildLaplacianPyr, src, levels, "UniformOutput", false);

%% Build mask pyramids
fprintf("Build Mask Gaussian pyramids...");
mask_pyrs = cellfun(@buildMaskPyr, masks, levels, "UniformOutput", false);

%% Blend Laplacian pyramids
fprintf("Blending...");
result_peak = zeros(size(peak{1}));
mass = zeros(size(peak{1}));
for n=1:img_num
    mask_pyr = mask_pyrs{n};
    result_peak = result_peak + peak{n}.*mask_pyr{end};
    mass = mask_pyr{end} + mass;
end
result_peak = result_peak./mass;

result_pyr = cell(level, 1);
for n=1:img_num
    lap_pyr = lap_pyrs{n};
    mask_pyr = mask_pyrs{n};
    for l=1:level
        if n==1
            result_pyr{l} = lap_pyr{l}.*mask_pyr{l};
        else
            result_pyr{l} = result_pyr{l} + lap_pyr{l}.*mask_pyr{l};
        end
    end
end

%% Reconstruct image
img_out = result_peak;
for i = level:-1:1
    up = myimpyramid(img_out, "expand", size(result_pyr{i}, 1, 2));
    img_out = up + result_pyr{i};
end
mask = ~isnan(img_out);
img_out (isnan(img_out)) = 0;

clear lap_pyrs mask_pyrs result_pyr peaks
fprintf("Done.\n");
end

function [ lap_pyr, peak ] = buildLaplacianPyr(img, levels)
    lap_pyr = cell(1, levels);
    cnt = img;
    for i = 1:levels
        down = myimpyramid(cnt, 'reduce');
        up = myimpyramid(down, 'expand', size(cnt, 1, 2));
        lap_pyr{i} = cnt - up;
        cnt = down;
    end
    peak = cnt;
    clear cnt;
end

function mask_pyr = buildMaskPyr(mask, levels)
    mask_pyr = cell(1, levels+1);
    cnt = double(mask);
    mask_pyr{1} = cnt;
    for i=2:levels+1
        down = impyramid(cnt, 'reduce');
        mask_pyr{i} = logical(down);
        cnt = down;
    end
end
