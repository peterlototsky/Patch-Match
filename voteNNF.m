% use the NNF to vote the source patches
function output = voteNNF(NNF, source_image)
    global patch_size;
    
    fprintf("Voting to reconstruct the final result...\n");
    
    source_size = size(source_image);
    target_size = size(NNF);
    
    output = zeros(target_size(1), target_size(2), 3);
    
    % write your code here to reconstruct the output using source image
    % patches
    
    % output = padarray(output,[floor(patch_size/2),floor(patch_size/2)],0,'both');

    source_image = padarray(source_image,[floor(patch_size/2),floor(patch_size/2)],'both','symmetric');
    averageArr = ones(size(output));

    
    for i = 1:1:size(NNF,1)
        for j = 1:1:size(NNF,2)
            [xright,xleft,yup,ydown] = CalcPatch(NNF,i,j);
            
            output( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) = output( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) + (source_image( abs(NNF(i,j,1) - yup):1:ydown + NNF(i,j,1), abs(NNF(i,j,2) - xleft):1:NNF(i,j,2) + xright,:));
            averageArr( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) = averageArr( abs(i - yup):1:i + ydown , abs(j - xleft):1:j + xright,:) + 1;

        end
    end


    output = output ./ averageArr;


    fprintf("Done!\n");
end


function [xright,xleft,yup,ydown] = CalcPatch(NNF,i,j)
    global patch_size;
    % calculate patch size
    xright = floor(patch_size/2);
    xleft = floor(patch_size/2);
    yup = floor(patch_size/2);
    ydown = floor(patch_size/2);

    if (j+xright > size(NNF,2))
        dif = abs(size(NNF,2) - j);
        xright = dif;
    end
    if (j - xleft < 0)
        dif = abs(xleft - j);
        xleft = xleft - dif;
    end
    if (i + ydown > size(NNF,1))
        dif = abs(size(NNF,1) - i);
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

end