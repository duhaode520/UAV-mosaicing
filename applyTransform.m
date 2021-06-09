function warped = applyTransform(point, T)
%applyTransform - apply Homography transformation
%
% Syntax: warped = applyTransform(point, T)
%
% Long description
    
point_num = size(point,1);
tmp_ori = [point ones(point_num, 1)];
tmp_des = tmp_ori * T(1:2, :).';
warped = tmp_des ./ (repmat(tmp_ori * T(end, :).',1, 2));

end