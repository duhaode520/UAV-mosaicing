function rebuild = rebuildMask(ori,x_lims, y_lims)
%rebuildMask - rebuild blend mask of each image using distance to each boundary
%
% Syntax: rebuild = rebuildMask(ori,x_lims, y_lims)
%
% Long description
% Input:
% ori: original masks
% x_lims, y_lims: x,y range of each image
% Output:
% rebuild: rebuilt mask with little overlap
img_num = length(ori);
img_size = size(ori{1});

%% Compute distance map
distance_maps = zeros(img_size(1), img_size(2), img_num);
for n=1:img_num
    [y, x] = find(ori{n} == 1);
    idx = sub2ind(img_size,y,x);
    xr = x_lims(n, :);
    yr = y_lims(n, :);
    dist_map = zeros(img_size);
    dist_map(idx) = min([y-yr(1)  yr(2)-y  x-xr(1) xr(2)-x], [], 2);
    max_dist = max(max(dist_map));

    distance_maps(:,:,n) = dist_map / max_dist; % normalization
end

%% rebuild masks
rebuild = cell(img_num, 1);
% 寻找对于拼接图像的每个像素来说距离边界最远的图像序号
[dist_max_map, dist_max_idx] = max(distance_maps, [], 3); 
invalid_idx = dist_max_map==0;
dist_max_idx(invalid_idx) = 0;

for n=1:img_num
    rebuild{n} = dist_max_idx == n;
end

