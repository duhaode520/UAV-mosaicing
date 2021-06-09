function transformers = adjustmentSparse(features, matches, matches_pos, img_num, ref)
%adjustmentSparse - adjust images and compute H using sparse matrix.
%
% Syntax: transformers = adjustment(features, matches, matches_pos, img_num, ref)
%
% Long description
% Input:
% features: cell array of all images' SIFT keypoints
% matches: cell array of all matches between images
% matches_pos: No. of images of matches
% img_num: total number of images
% ref: No. of reference image
% Output:
% tranformers: 3*3*img_num array, transformers of all other images to referernce image
    
%% Preparing
% Computing pair index of each match
pair_num = 0;
idx_match_starts = [];
for n = 1:length(matches)
        match = matches{n};
        idx_match_starts = [idx_match_starts, size(match, 2)];
        pair_num = pair_num + size(match, 2);
end
idx_match_starts = [0 cumsum(idx_match_starts)];

% Preparing to construct sparse matrix A
rowA = [];
colA = [];
valueA = [];
B = [];

%% Constructing sparse matrix
fprintf("Constructing matrix\n");
parfor_progress(length(matches));
parfor n = 1:length(matches)
    match = matches{n};
    if isempty(match)
        continue;
    end
    
    match_start = idx_match_starts(n);
    pos = matches_pos(n,:);
    i = pos(1); j = pos(2);
    match_size = size(match, 2);

    if i > j
        t = i;
        i = j;
        j = t;
    end
    
    % load feature and match points
    f1 = features{i}; 
    f2 = features{j}; 
    points1 = f1(1:2,match(1,:));
    points2 = f2(1:2,match(2,:));
    
    % local row, col, val of A
    rA = zeros(6*match_size, 1);
    cA = zeros(6*match_size, 1);
    vA = zeros(6*match_size, 1);
    b = zeros(2*match_size, 1);
    
    if (i ~= ref) && (j ~= ref)
        rA = zeros(12*match_size, 1);
        cA = zeros(12*match_size, 1);
        vA = zeros(12*match_size, 1);
    end

    for incre=1:size(match,2)
        idx_match = match_start + incre;
        
        point1 = points1(:, incre);
        point2 = points2(:, incre);
        if (i ~= ref) && (j ~= ref) % either of 2 images is reference
            rA(6*incre-5:6*incre) = [(2*idx_match-1)*ones(3, 1) 2*idx_match*ones(3, 1)];
            cA(6*incre-5:6*incre) = [6*i-5, 6*i-4, 6*i-1, 6*i-3, 6*i-2, 6*i-0];
            vA(6*incre-5:6*incre) = [point1; 1; point1; 1];

            rA(6*incre-5+6*match_size:6*incre+6*match_size) = [(2*idx_match-1)*ones(3, 1) 2*idx_match*ones(3, 1)];
            cA(6*incre-5+6*match_size:6*incre+6*match_size) = [6*j-5, 6*j-4, 6*j-1, 6*j-3, 6*j-2, 6*j-0];
            vA(6*incre-5+6*match_size:6*incre+6*match_size) = [-point2 ;-1 ;-point2; -1];
            
        elseif (j == ref) && (i ~= ref) % j is reference
            rA(6*incre-5:6*incre) = [(2*idx_match-1)*ones(3, 1) 2*idx_match*ones(3, 1)];
            cA(6*incre-5:6*incre) = [6*i-5, 6*i-4, 6*i-1, 6*i-3, 6*i-2, 6*i-0];
            vA(6*incre-5:6*incre) = [point1 ;1 ;point1; 1];

            b(2*incre-1:2*incre) = point2(1:2);

        elseif (i== ref) && (j ~= ref) % i is reference
            rA(6*incre-5:6*incre) = [(2*idx_match-1)*ones(3, 1) 2*idx_match*ones(3, 1)];
            cA(6*incre-5:6*incre) = [6*j-5, 6*j-4, 6*j-1, 6*j-3, 6*j-2, 6*j-0];
            vA(6*incre-5:6*incre) = [point2 ;1 ;point2 ;1];
        
            b(2*incre-1:2*incre) = point1(1:2);
        end
    end
    
    rowA = [rowA;rA];
    colA = [colA;cA];
    valueA = [valueA;vA];
    B = [B;b];
    parfor_progress;
end
parfor_progress(0);

%% Solving equation
fprintf("Sparse linear equation solving...\n");
A = sparse(rowA, colA, valueA, 2*pair_num, 6*max(matches_pos,[], 'all'));
A = [A(:, 1:6*ref-6) A(:, 6*ref+1:end)]; % delete reference image to ensure full rank
A(:,all(A==0,1))= []; % remove columns with all 0;
X = A\B;

X = full(X);
X = [X(1:6*ref-6) ;zeros(6,1); X(6*ref-5:end)]; % add the transformer of referenc image back
transformers = zeros(3, 3, img_num);

%% Build transformers
for i = 1:img_num
    if i == ref
        continue;
    end
    transformers(1,1,i) = X(6*i-5);
    transformers(1,2,i) = X(6*i-4);
    transformers(2,1,i) = X(6*i-3);
    transformers(2,2,i) = X(6*i-2);
    transformers(1,3,i) = X(6*i-1);
    transformers(2,3,i) = X(6*i-0);
end

transformers(1,1,ref) = 1;
transformers(2,2,ref) = 1;
transformers(3,3,:) = 1;
end