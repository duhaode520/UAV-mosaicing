%% Preparation
clear all;
addpath("parfor_progress");
% Setup VLfeat tools%
cd vlfeat-0.9.14/toolbox;
vl_setup();
cd ../..;

% Check if already running parallel
if isempty(gcp('nocreate')) %if not, we attempt to do it:
   parpool('local');
end

% Pre-defined parameters
scale = 1;

% Read images 
img_path = 'dataset/HeJiaDong2/';
img_files = dir(strcat(img_path, '*.JPG'));
img_num = length(img_files);
img_list = cell(img_num,1);
if img_num > 0
    for i = 1:img_num
        img_name = img_files(i).name;
        img = imresize(imread(strcat(img_path, img_name)), scale);
        img_list{i} = img;
    end
end
fprintf("Read %d images from %s\n", img_num, img_path);

%% SIFT detecting and matching
% Find SIFT features for all pictures 
fprintf("SIFT feature detecting.\n");
SIFT_features = cell(1, img_num);
SIFT_descriptor = cell(1, img_num);

parfor i=1:img_num
    [feature,dp] = vl_sift(single(rgb2gray(img_list{i})),'PeakThresh', 0,'edgethresh',100);
    SIFT_features{i} = feature;
    SIFT_descriptor{i} = dp;
end

fprintf("Match SIFT features\n");
match_num = (img_num-1)*img_num/2;
img_matches = cell(1, match_num);
matches_pos = [];

% Record No. of match images
for i = 1:img_num
    for j = i+1:img_num
        matches_pos = [matches_pos ;[i,j]];
    end
end

% Match features 
% using parfor to accelerate
parfor_progress(match_num);
match_size = zeros(match_num, 1);
parfor n = 1:match_num
    pos= matches_pos(n, :);
    i = pos(1);
    j = pos(2);
    
    if i > j
        t = i;
        i = j;
        j = t;
    end
    
    if i ~= j
        matches = GetImageMatches(SIFT_features{i}, SIFT_features{j}, ...
                SIFT_descriptor{i}, SIFT_descriptor{j});
        img_matches{n} = matches;
        match_size(n) = size(matches, 2);
    end
    parfor_progress;
end
parfor_progress(0);
save matches
%% Delete Invalid images
load matches
fprintf("Find max connect componets.\n");
img_match_mat = cell(img_num, img_num);
max_match_size = max(match_size);
conn_thresh = 0.07;

% Build connection matrix
for n = 1:length(img_matches)
    i = matches_pos(n, 1);
    j = matches_pos(n, 2);
    match = img_matches{n};
    if size(match, 2) < conn_thresh*max_match_size % delete insignificiant or error matches
        match = [];
        img_matches{n} = [];
    end
    img_match_mat{i,j} = match;
    img_match_mat{j,i} = match;
end
connection = 1- cellfun(@isempty, img_match_mat);

% Find max connective and delete
max_conn = findMaxConnected(connection);
img_list = img_list(max_conn);
valid = min(ismember(matches_pos, max_conn), [], 2);
matches_pos = matches_pos(valid, :);
% img_match_mat = img_match_mat(max_conn, max_conn);
img_matches = img_matches(valid);
img_num = length(img_list);
clear max_conn valid connection match match_size match_pos

%% Global adjustment
ref = ceil(img_num/2); % No. of reference image, arbitrary using mid
fprintf("Global adjustment with image %d.\n", ref);
transformers = adjustmentSparse(SIFT_features, img_matches,matches_pos, img_num, ref);
% save matches

%% Delete images with big overlapping
%  load matches
delete_idx = resampleByOverlap(img_list, transformers, 0.6);
transformers = transformers(:,:,delete_idx);
img_list = img_list(delete_idx);
img_num = length(img_list);
fprintf("Using %d images to execute final blending\n", img_num);
clear delete_idx;

%% Computing the size of new image
% load matches
polygons = cell(img_num, 1);
quad_xlims = zeros(img_num, 2);
quad_ylims = zeros(img_num, 2);

parfor n=1:img_num
   [h, w] = size(img_list{n}, 1, 2);
   corner = ...
   [
       w,1;
       1,1;
       1,h;
       w,h;
   ];
   T = transformers(:,:,n);
   quad_corners = applyTransform(corner, T);
   polygon = polyshape(quad_corners);
   [quad_xlims(n,:), quad_ylims(n, :)] = boundingbox(polygon);
   polygons{n} = polygon;
end

box_min = [min(quad_xlims(:, 1)), min(quad_ylims(:, 1))];
box_max = [max(quad_xlims(:, 2)), max(quad_ylims(:, 2))];
dG = -box_min; % bias

new_size = box_max-box_min;
new_width = int32(new_size(1) + .5);
new_height = int32(new_size(2) + .5);
fprintf("New width: %d; New height: %d\n", new_width, new_height);


%% Image warping
fprintf("Image Warping\n");
% Release memory
clear img_match_mat img_matches SIFT_descriptor SIFT_features
clear max_conn valid connection match match_size match_pos
% Build Mesh
warp_images = cell(img_num,1);
warp_masks = cell(img_num,1);
x_range = box_min(1):box_max(1);
y_range = box_min(2):box_max(2);
[x_grid, y_grid] = meshgrid(x_range, y_range);

% warping
% start_idx = 10;
% end_idx = min([5, length(img_list)]);
parfor_progress(img_num);
for n=1:img_num
    [warp_images{n}, warp_masks{n}] = imageWarping(img_list{n}, transformers(:,:,n), x_grid, y_grid);
    parfor_progress;
    clear img_list(n)
end
parfor_progress(0);
clear img_list x_grid y_grid

%% Rebuild masks
fprintf("Rebuild masks with image boundary.\n");
quad_xlims = quad_xlims+dG(1);
quad_ylims = quad_ylims+dG(2);
new_masks = rebuildMask(warp_masks, quad_xlims, quad_ylims);
% save matches_test
clear polygon quad_xlims quad_ylims warp_masks

%% Image blend
fprintf("Laplacian blending.\n");
% mosaic = linearBlend(warp_images, new_masks);
mosaic = lapBlend(warp_images, new_masks, 2, 3);
imshow(mosaic);
imwrite(mosaic, "HeJiaDong2test.png");
