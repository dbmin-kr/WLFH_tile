function prepare_lftile(directoryName, fileNameHeader, param)

directory_LF_full = '/LF_full';
directory_LF_tile_header = './LF_tiles/tile_';

for tileX = 1:param.NtileX
    for tileY = 1:param.NtileY
        mkdir([directoryName, directory_LF_tile_header, num2str(tileX),'_',num2str(tileY)]);
    end
end

NxTile_minus_overlap = param.NxTile - param.overlapX;
NyTile_minus_overlap = param.NyTile - param.overlapY;

for idxU = 1 : param.NuFile
    for idxV = 1 : param.NvFile
        idxFile = idxU + (idxV-1)*param.NuFile;
        original = imread([directoryName, directory_LF_full,'/',fileNameHeader, num2str(idxFile,'%04d'),'.png']);
        for tileX = 1 : param.NtileX
            for tileY = 1 : param.NtileY
                startX = NxTile_minus_overlap*(tileX-1) + 1;
                endX = min(startX + param.NxTile - 1, param.NxFile);
                startY = NyTile_minus_overlap*(tileY-1) + 1;
                endY = min(startY + param.NyTile- 1, param.NyFile);
                
                tile = original( startY:endY, startX:endX, :);
                imwrite(tile, [directoryName, directory_LF_tile_header, num2str(tileX),'_',num2str(tileY),'/', fileNameHeader, num2str(idxFile,'%04d'),'.png'])
            end
        end
    end
    idxU
end