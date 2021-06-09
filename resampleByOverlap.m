function idx = resampleByOverlap(img_list, transformers, overlap_thresh)
%resampleByOverlap - resample images by overplapping
%
% Syntax: idx = resampleByOverlap(img_list, transformers)
%
% Long description
% Output:
% idx: logical array, is image deleted
if nargin < 3
    overlap_thresh = 0.7;
end
img_num = length(img_list);
idx = ones(img_num, 1);

for i = 2:img_num
   statisfied = true; 
   [h, w] = size(img_list{i}, 1, 2);
   corner = ...
   [
       w,1;
       1,1;
       1,h;
       w,h;
   ];
%    tmp_ori = [corner ones(4,1)];

   T = transformers(:,:,i);
%    tmp_des = tmp_ori * T(1:2, :).';
%    quad_corner1 = tmp_des ./ (repmat(tmp_ori * T(end, :).',1, 2));
   quad_corner1 = applyTransform(corner, T);
   polygon1 = polyshape(quad_corner1);
   quad_area1 = area(polygon1);


   for j = 1:i-1
       if(idx(j) == false)
           continue
       end
       [h, w] = size(img_list{j}, 1, 2);
       corner = ...
       [
            w,1;
            1,1;
            1,h;
            w,h;
       ];
    %    tmp_ori = [corner ones(4,1)];

       T = transformers(:,:,j);
       quad_corner2 = applyTransform(corner, T);
    %    quad_corner2 = tmp_ori * T(1:2, :).' ./ repmat(tmp_ori * T(end, :).',1, 2);
       polygon2 = polyshape(quad_corner2);
       poly_inter = intersect(polygon1, polygon2);
       quad_area2 = area(poly_inter);

       if (quad_area2/quad_area1 > overlap_thresh)
           statisfied = false;
           break;
       end 
   end

   idx(i) = statisfied;
end
    idx = logical(idx);
end