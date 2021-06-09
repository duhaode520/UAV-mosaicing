function [inner_matches, H] = GetImageMatches(feature1, feature2, dep1,dep2)
%GETIMAGEMATCHES get matches of sift features using FLANN and RANSAC
%   
    matches = vl_ubcmatch(dep1, dep2);
    numMatches = size(matches, 2);
    if numMatches == 0
        inner_matches = [];
        return;
    end
    X1 = feature1(1:2,matches(1,:)) ; X1(3,:) = 1 ;
    X2 = feature2(1:2,matches(2,:)) ; X2(3,:) = 1 ;

    %% RANSAC with homography model
    clear H score ok;
    % set param
    max_iter = 100;
    for t = 1:max_iter
        % estimate homography
        subset = vl_colsubset(1:numMatches, 4) ;%1~nummatches ȡ����ĸ���
        A = [] ;
        for i = subset
            A = cat(1, A, kron(X1(:,i)', vl_hat(X2(:,i)))) ;%cat(1,A,B)���з�����ƴ�Ӿ���kron(A,B)��ʾ[A(1,1)*B,A(1,2)*B,...]ÿ���������з�����ƴ�ӣ�vl_hat(A)��A���һ��3*3�ķ��Գƾ���
        end
        [U,S,V] = svd(A) ;%U*S*V'=A
        H{t} = reshape(V(:,9),3,3) ; % reshape to 3*3 matrix
        
        % score homography
        X2_ = H{t} * X1 ;
        du = X2_(1,:)./X2_(3,:) - X2(1,:)./X2(3,:) ;
        dv = X2_(2,:)./X2_(3,:) - X2(2,:)./X2(3,:) ;
        ok{t} = (du.*du + dv.*dv) < 6*6 ;
        score(t) = sum(ok{t}) ;
    end

    [score1, best] = max(score) ;
    H = H{best} ;
    ok = ok{best} ;
    
    inner_matches = matches(:, ok);
end


