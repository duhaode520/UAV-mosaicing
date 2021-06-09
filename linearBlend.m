% function result = linearBlend(images, masks)
%     img_num = length(images);
%     result = zeros(size(images{1}));
%     mass = zeros(size(images{1}));
%     for n=1:img_num
%         mask = masks{n};
%         result = result + images{n}.*mask;
%         mass = mask + mass;
%     end
%     result = result./mass;
% end

function result = linearBlend(images, masks)

    img_num = length(images);

    result = zeros(size(images{1}));
    w_sum = zeros(size(masks{1}));
    for n = 1:img_num
            w = mat2gray(images{n});
            result = result + images{n}.*w;
            w_sum = w_sum+w;
    end
    result = result./ w_sum;
end