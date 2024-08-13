function nhlfh_Wtile_nocolor(directoryName, fileNameHeader, is_mask, idxColor, WtileDirectoryName, param, useGpu, verbose)

mkdir([directoryName,'/NHLFH_tiles']);

for tileX = 1:param.NtileX
    for tileY = 1:param.NtileY
        idxFile = 1;
        temp = imread([directoryName,'/LF_tiles/tile_', num2str(tileX),'_',num2str(tileY),'/', fileNameHeader, num2str(idxFile,'%04d'),'.png']);
        [NyFile, NxFile, ~] = size(temp);
        clear temp
        
        NxL = NxFile; NyL = NyFile;
        lightFieldBeforeUVcompensation = zeros(NyL,NxL,param.NvFile,param.NuFile);
        
        %tic
        for idxU=1:param.NuFile
            for idxV=1:param.NvFile
                idxFile = idxU + (idxV-1)*param.NuFile;
                temp = imread([directoryName,'/LF_tiles/tile_', num2str(tileX),'_',num2str(tileY),'/', fileNameHeader, num2str(idxFile,'%04d'),'.png']);
                switch idxColor
                    case 1
                        temp = double(temp(:,:,1));
                    case 2
                        temp = double(temp(:,:,2));
                    case 3
                        temp = double(temp(:,:,3));
                    case 4
                        temp = double(rgb2gray(temp));
                end
                if is_mask
                    threshold = 0;
                    temp = double(temp>threshold);
                end
                lightFieldBeforeUVcompensation( :, :, idxV, idxU) = temp;  
            end
        end
        %elapsedTime = toc;
        %disp(['Loading time for light field files =', num2str(elapsedTime),' sec.'])
       
        % Wtile
        load([directoryName,'/',WtileDirectoryName,'/', 'wt_',num2str(tileX),'_',num2str(tileY)],'Wtile');
        hologramTile = LF2H_usingW(lightFieldBeforeUVcompensation, Wtile, param.M, param.bufferX, param.bufferY, useGpu, verbose);
        [NyHT, NxHT] = size(hologramTile);
        
        % Normalization
        hologramTile = hologramTile * param.du * param.dv * param.dxH * param.dyH;
        hologramTile = single(hologramTile);
        save([directoryName,'/NHLFH_tiles/', 'ht_',num2str(tileX),'_',num2str(tileY)],'hologramTile');
        save([directoryName,'/NHLFH_tiles/', 'ht_dimension_',num2str(tileX),'_',num2str(tileY)],'NxHT','NyHT');
        disp(['NHLFH for tileX=',num2str(tileX),'  tileY=',num2str(tileY),' has just been created.'])
    end
end
end