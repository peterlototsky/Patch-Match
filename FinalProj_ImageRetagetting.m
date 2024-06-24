clear;
clc;
close all;
global patch_size;
patch_size = 11;
%% PART 2 - IMAGE RETARGETTING
%%% Declaring parameters for the retargeting
minImgSize = 30;                % lowest scale resolution size for min(w, h)
outSizeFactor = [1, 0.65];		% the ratio of output image
numScales = 10;                 % number of scales (distributed logarithmically)

%% Preparing data for the retargeting
image = imread('SimakovFarmer.png');
[h, w, ~] = size(image);

targetSize = outSizeFactor .* [h, w];
% imageLab = rgb2lab(image); % Convert the source and target Images
% imageLab = double(imageLab)/255;
imageLab = im2double(image);


coarseLevelH = ceil(h* minImgSize / (w * outSizeFactor(2)));
coarseW = ceil(h* minImgSize / (h * outSizeFactor(2)));
percentResize = coarseLevelH / h;
steps = (1-percentResize)/(numScales- 1);
ImgScales = cell(numScales,1);
ImgScales{1} = imageLab;

ind = 1;
for i = 2:1:numScales
    ImgScales{i,1} = imresize(ImgScales{1,1},1-(steps*ind),'bicubic');
    ind = ind + 1;
end

% Gradual Scaling - iteratively icrease the relative resizing scale between the input and
% the output (working in the coarse level).
%% STEP 1 - do the retargeting at the coarsest level

 target_image = ImgScales{numScales};
 imshow(target_image)

 percentResize = minImgSize / coarseLevelH;
 steps = (1-percentResize)/(numScales- 1);

 for i=1:numScales
    target_image = imresize(target_image,[coarseLevelH,coarseW*(1-steps*i)],'bicubic');
    target_image = patchMatchNNF(target_image, ImgScales{numScales});
    target_image = voteNNF(target_image,ImgScales{numScales});
    imshow(target_image)

 end

%% STEP 2 - do resolution refinment 
% (upsample for numScales times to get the desired resolution)

 dify = (coarseLevelH / coarseLevelH);
 difx = (minImgSize / coarseW);

 for i=2:numScales
    source_size = size(ImgScales{numScales- i + 1});
    target_image = imresize(target_image, [floor(dify.* source_size(1)), floor(difx.*source_size(2))], "bicubic");
    target_image = patchMatchNNF(target_image, ImgScales{numScales- i + 1});
    target_image = voteNNF(target_image, ImgScales{numScales- i + 1});

    imshow(target_image)
 end
% (refine the result at the last scale)
