% computes the NNF between patches in the target image and those in the source image
function NNF = patchMatchNNF(target_image, source_image, source_alpha)
    global patch_size;
    
    fprintf("Computing NNF using PatchMatch...\n");
    
    target_size = size(target_image);
    source_size = size(source_image);

    % initialize the NNF
    NNF = zeros(target_size(1), target_size(2), 2);
    
    tic

    padTarget = padarray(target_image,[floor(patch_size/2),floor(patch_size/2)],0,'both');
    padSource = padarray(source_image,[floor(patch_size/2),floor(patch_size/2)],'both','symmetric');
    padAlpha = padarray(source_alpha,[floor(patch_size/2),floor(patch_size/2)],0,'both');

    rng('default')

    
    ind = 1;
    for i = 1:1:size(source_image,1)
        for j = 1:1:size(source_image,2)
            
            if(source_alpha(i,j) > 0.999)
                possibleNNF{ind} = [i j];
                ind = ind + 1;
            end

        end
    end

    for i = 1:1:size(NNF,1)
        for j = 1:1:size(NNF,2)
            
            randnum = possibleNNF{randi(size(possibleNNF,2))};
            NNF(i,j,1) = randnum(1);
            NNF(i,j,2) = randnum(2);


        end
    end

    NNF(:,:,:) = NNF(:,:,:) + floor(patch_size/2);


    % Calculate distances between patches

    for i = 1:1:size(target_image,1)
        for j = 1:1:size(target_image,2)

            % patchComp = abs( padTarget( (NNF(i,j,1)-(floor(patch_size/2))):1:(NNF(i,j,1)+(floor(patch_size/2))) , (NNF(i,j,2)-(floor(patch_size/2))):1:(NNF(i,j,2)+(floor(patch_size/2))),:) - padSource( (NNF(i,j,1)-(floor(patch_size/2))):1:(NNF(i,j,1)+(floor(patch_size/2))) , (NNF(i,j,2)-(floor(patch_size/2))):1:(NNF(i,j,2)+(floor(patch_size/2))),:));
            % totalSum = sum(patchComp,'all');
            totalSum = CalcPatchDistanceinitial(NNF,i,j,padSource,target_image);
            NNF(i,j,3) = totalSum;

        end
    end

    for inter = 1:1:15
        
        NNF = propogate(NNF, target_image, padSource, source_image);
        NNF = randomSearch(NNF, padSource, target_image);


    end

    toc

    fprintf("Done!\n");
end

function NNFout = randomSearch(NNF, padSource, target_image)
global patch_size;
windowSize = size(NNF);

row = 1 + floor(patch_size/2);
col = 1 + floor(patch_size/2);
for i = 1:1:size(NNF,1)
    for j = 1:1:size(NNF,2)
       
        while (windowSize(1) > 3 && windowSize(2) > 3)

            [x,y] = getxy(target_image, windowSize,i,j);

            totalSum = CalcPatchRand(NNF,i,j,padSource,target_image,x,y);
            if (totalSum < NNF(i,j,3))

                NNF(i,j,3) = totalSum;
                NNF(i,j,1) = NNF(y,x,1);
                NNF(i,j,2) = NNF(y,x,2);
        
            end


            windowSize(1) = windowSize(1)/2;
            windowSize(2) = windowSize(2)/2;

        end
        col = col + 1;
        windowSize = size(NNF);
    end
    row = row + 1;
    col = 1 + floor(patch_size/2);
end

    NNFout = NNF;

end
    
function [xout,yout] = getxy(target_image,windowSize,i,j)

    xright = floor(windowSize(2)/2);
    xleft = floor(windowSize(2)/2);
    yup = floor(windowSize(1)/2);
    ydown = floor(windowSize(1)/2);
        
    if (j+xright > size(target_image,2))
        dif = abs(size(target_image,2) - j);
        xright = dif;
    end
    if (j - xleft <= 0)
        dif = abs(xleft - j);
        xleft = xleft - dif;
    end
    if (i + ydown > size(target_image,1))
        dif = abs(size(target_image,1) - i);
        ydown = dif;
    end
    if (i - yup <= 0)
        dif = abs(yup - i);
        yup = yup - dif;
    end

    xout = randi([abs(j-xleft)+1 j+xright]);
    yout = randi([abs(i-yup)+1 i+ydown]);

end

function distance = CalcPatchDistanceinitial(NNF,i,j,padSource,target_image)
    global patch_size;
    % calculate patch size
    xright = floor(patch_size/2);
    xleft = floor(patch_size/2);
    yup = floor(patch_size/2);
    ydown = floor(patch_size/2);

    if (j+xright > size(target_image,2))
        dif = abs(size(target_image,2) - j);
        xright = dif;
    end
    if (j - xleft < 0)
        dif = abs(xleft - j);
        xleft = xleft - dif;
    end
    if (i + ydown > size(target_image,1))
        dif = abs(size(target_image,1) - i);
        ydown = dif;
    end
    if (i - yup < 0)
        dif = abs(yup - i);
        yup = yup - dif;
    end

    if (i - yup == 0)
        yup = 0;
    end 
    if (j - xleft == 0)
        xleft = 0;
    end

    
    patchComp = ( target_image( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) - padSource( (NNF(i,j,1)-yup):1:(NNF(i,j,1)+ydown) , (NNF(i,j,2)-xleft):1:(NNF(i,j,2)+xright),:)).^2;
    distance = sum(patchComp,'all') / ( (xright + xleft) * (ydown + yup));

end

function NNFout = propogate(NNF, target_image, padSource, source_image)

    % 1 = left nnf = right Source
    % 2 = right nnf = left Source
    % 3 = up nnf = down Source
    % 4 = down nnf = up Source
for initer = 1:1:4
    for i = 2:1:size(NNF,1)-1
        for j = 2:1:size(NNF,2)-1
            
            NNF = computeDifProp(i,j,initer, source_image, target_image, padSource, NNF);
        end
    end
end
    NNFout = NNF;
end

function NNFout = computeDifProp(i,j,direction, source_image, target_image, padSource, NNF)
    global patch_size;  
     row = i + floor(patch_size/2);
     col = j + floor(patch_size/2);
     if (direction == 1)
        x = NNF(i,j-1,2);
        y = NNF(i,j-1,1);
        
        if (x + 1 <= size(source_image,2))
            % patchComp = abs(  - padSource( y-(floor(patch_size/2)):1:y+(floor(patch_size/2)) , x+1-(floor(patch_size/2)):1:x+1+(floor(patch_size/2)),:));
            totalSum = CalcPatchProp(NNF,i,j,padSource,target_image,x+1,y);
            if (totalSum < NNF(i,j,3))
                NNF(i,j-1,3) = totalSum;
                NNF(i,j-1,1) = y;
                NNF(i,j-1,2) = x+1;
        
            end
        end  
     elseif(direction == 2)
        x = NNF(i,j+1,2);
        y = NNF(i,j+1,1);

        if (x - 1 - floor(patch_size/2) > 0 && x + 1 <= size(source_image,2))
            % patchComp = abs( padTarget( row-(floor(patch_size/2)):1:row+(floor(patch_size/2)), col-(floor(patch_size/2)):1:col+(floor(patch_size/2)),:) - padSource( y-(floor(patch_size/2)):1:y+(floor(patch_size/2)) , x-1-(floor(patch_size/2)):1:x-1+(floor(patch_size/2)),:));
            totalSum = CalcPatchProp(NNF,i,j,padSource,target_image,x-1,y);
            if (totalSum < NNF(i,j,3))

                NNF(i,j,3) = totalSum;
                NNF(i,j,1) = y;
                NNF(i,j,2) = x - 1;
        
            end

        end
     elseif(direction == 3)
        x = NNF(i-1,j,2);
        y = NNF(i-1,j,1);

        if (y + 1 <= size(source_image,1))
            % patchComp = abs( padTarget( row-(floor(patch_size/2)):1:row+(floor(patch_size/2)), col-(floor(patch_size/2)):1:col+(floor(patch_size/2)),:) - padSource( y+1-(floor(patch_size/2)):1:y+1+(floor(patch_size/2)) , x-(floor(patch_size/2)):1:x+(floor(patch_size/2)),:));
            totalSum = CalcPatchProp(NNF,i,j,padSource,target_image,x,y+1);
            if (totalSum < NNF(i,j,3))

                NNF(i,j,3) = totalSum;
                NNF(i,j,1) = y + 1;
                NNF(i,j,2) = x;
        
            end

        end
     elseif(direction == 4)
        x = NNF(i+1,j,2);
        y = NNF(i+1,j,1);

        if (y - 1 - floor(patch_size/2) > 0 && y + 1 <= size(source_image,1))
            % patchComp = abs( padTarget( row-(floor(patch_size/2)):1:row+(floor(patch_size/2)), col-(floor(patch_size/2)):1:col+(floor(patch_size/2)),:) - padSource( y-1-(floor(patch_size/2)):1:y-1+(floor(patch_size/2)) , x-(floor(patch_size/2)):1:x+(floor(patch_size/2)),:));
            totalSum = CalcPatchProp(NNF,i,j,padSource,target_image,x,y-1);
            if (totalSum < NNF(i,j,3))

                NNF(i,j,3) = totalSum;
                NNF(i,j,1) = y - 1;
                NNF(i,j,2) = x;
        
            end

        end  
     end

     NNFout = NNF;

end

function distance = CalcPatchRand(NNF,i,j,padSource,target_image,x,y)
    global patch_size;
    % calculate patch size
    xright = floor(patch_size/2);
    xleft = floor(patch_size/2);
    yup = floor(patch_size/2);
    ydown = floor(patch_size/2);

    if (j+xright > size(target_image,2))
        dif = abs(size(target_image,2) - j);
        xright = dif;
    end
    if (j - xleft < 0)
        dif = abs(xleft - j);
        xleft = xleft - dif;
    end
    if (i + ydown > size(target_image,1))
        dif = abs(size(target_image,1) - i);
        ydown = dif;
    end
    if (i - yup < 0)
        dif = abs(yup - i);
        yup = yup - dif;
    end

    if (i - yup == 0)
        yup = 0;
    end 
    if (j - xleft == 0)
        xleft = 0;
    end

    
    patchComp = ( target_image( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) - padSource( (NNF(y,x,1)-yup):1:(NNF(y,x,1)+ydown) , (NNF(y,x,2)-xleft):1:(NNF(y,x,2)+xright),:)).^2;
    distance = sum(patchComp,'all') / ( (xright + xleft) * (ydown + yup));

end

function distance = CalcPatchProp(NNF,i,j,padSource,target_image,x,y)
    global patch_size;
    % calculate patch size
    xright = floor(patch_size/2);
    xleft = floor(patch_size/2);
    yup = floor(patch_size/2);
    ydown = floor(patch_size/2);

    if (j+xright > size(target_image,2))
        dif = abs(size(target_image,2) - j);
        xright = dif;
    end
    if (j - xleft < 0)
        dif = abs(xleft - j);
        xleft = xleft - dif;
    end
    if (i + ydown > size(target_image,1))
        dif = abs(size(target_image,1) - i);
        ydown = dif;
    end
    if (i - yup < 0)
        dif = abs(yup - i);
        yup = yup - dif;
    end

    if (i - yup == 0)
        yup = 0;
    end 
    if (j - xleft == 0)
        xleft = 0;
    end

    
    patchComp = ( target_image( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) - padSource( (y-yup):1:(y+ydown) , (x-xleft):1:(x+xright),:)).^2;
    distance = sum(patchComp,'all') / ( (xright + xleft) * (ydown + yup));

end