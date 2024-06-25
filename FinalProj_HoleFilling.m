clear;
clc;
close all;

global patch_size;
patch_size = 11; 

%% PART 1 - SINGLE IMAGE HOLE FILLING

% NOTE - If you are using the mex files on GS during the development of your
% code, make sure your refer to the README

%% STEP 1 - Read in the image with the hole region 
% Read in the image, convert to RGBA with holes denoted by 0 alpha.
% Identify the region and size of the hole.

[Img,~,Img_alpha] = imread("testimg2.png");

% find hole size

% left dim hole max
[row1,col1] = find(Img_alpha ~= 255,1,'first');
% right dim hole max
[row2,col2] = find(Img_alpha ~= 255,1,'last');
Img_alpha = rot90(Img_alpha);
% top dim hole max
[row3,col3] = find(Img_alpha ~= 255,1,'first');
% bottom dim hole max
[row4,col4] = find(Img_alpha ~= 255,1,'last');
Img_alpha = rot90(Img_alpha,3);

% store height and width of hole
holeSize = [col4 - col3,col2 - col1];

%% STEP 2 - Downsample image
% Iteratively downsample image till the dimension of the path is around the dimension
% of the hole. Store images at these multiple scales

% Parameters
numScales = 10;                 % number of scales

% store images in increasing order

% height = 1
% width = 2


Img = im2double(Img);
Img_alpha = im2double(Img_alpha);

[smallestDim, dim] = max(holeSize);



startSize = patch_size/smallestDim;
stepsize = (1-startSize)/(numScales - 1);

% ImgScales stores the scaled images

ImgScales = cell(numScales,2);
ImgScales{10,1} = Img;
ImgScales{10,2} = Img_alpha;

ind = 0;
for i = 1:1:numScales-1

    ImgScales{i,1} = imresize(Img, startSize+stepsize*ind);
    ImgScales{i,2} = imresize(Img_alpha,startSize+stepsize*ind);
    ind = ind + 1;

end

%% STEP 3 - Perform Hole filling
% Perform hole filling at each scale, starting at the coarsest. Use
% repeated search and vote steps (refer to HW8 and the final project 
% descriptions) at each scale till values within the hole have converged.
% Pixels in the hole region are the targets, patches outside the hole are
% the source.
% Upsample the resulting image, and blend it with the original downsampled
% image at the same scale, to refine the values outside the hole.

% fill smallest image hole with gradient of edge pixels

ImgFill = ImgScales{1,1};
tempAlpha = ImgScales{1,2};

for i = 1:1:size(ImgFill,1)
    start = 0;
    ishole = 0;
    for j = 1:1:size(ImgFill,2)
        
        if (tempAlpha(i,j) > 0.999)
            if (ishole == 1)
                pixcol1 = ImgFill(i,start,:);
                pixcol2 = ImgFill(i,j,:);

                for k = start+1:j-1
                    ImgFill(i,k,:) = pixcol1 + (k-start) * (pixcol2 - pixcol1) / (j - start);
                end
            end
            start = j;
        else
            ishole = 1;
        end

    end
end

% start patch match proccess
% first step
NNF = patchMatchNNFHole(ImgFill, ImgScales{1,1}, ImgScales{1,2});
ImgScales{1,1} = voteNNFHole(NNF, ImgScales{1,1}, ImgScales{1,2});


% rest of the steps


for i = 2:1:numScales
    ImgFill = imresize(ImgScales{i-1,1}, [size(ImgScales{i,1},1), size(ImgScales{i,2},2)],'bicubic');
    
    ImgFill = (ImgFill .* abs(1 - abs(ImgScales{i,2})));
    
    ImgFill = ImgFill + (abs(ImgScales{i,2}) .* (ImgScales{i,1}));
    NNF = patchMatchNNFHole(ImgFill, ImgScales{i,1}, ImgScales{i,2});
    ImgScales{i,1} = voteNNFHole(NNF, ImgScales{i,1}, ImgScales{i,2});
    

end

figure(2)
imshow(ImgScales{numScales,1})







