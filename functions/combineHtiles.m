function combined_hologram = combineHtiles(directoryName, startTileX, endTileX, startTileY, endTileY, param)
NxH=0; NyH=0;
endActiveX=0;
endActiveY=0;
for tileX = startTileX:endTileX
    tileY = startTileY;
    load([directoryName,'/ht_dimension_',num2str(tileX),'_',num2str(tileY)])
    if tileX==startTileX
        NxH = NxHT;
        endActiveX = NxH - param.bufferX;
    else
        NxH = endActiveX - param.bufferX + NxHT - 1;
        endActiveX = NxH - param.bufferX;
    end
end
for tileY = startTileY:endTileY
    tileX = startTileX;
    load([directoryName,'/ht_dimension_',num2str(tileX),'_',num2str(tileY)])
    if tileY==startTileY
        NyH = NyHT;
        endActiveY = NyH - param.bufferY;
    else
        NyH = endActiveY - param.bufferY + NyHT - 1;
        endActiveY = NyH - param.bufferY;
    end
end

endActiveX=0;
endActiveY=0;
combined_hologram = zeros(NyH, NxH);
for tileX = startTileX:endTileX
    if tileX==startTileX
        sx = 1;
    else
        sx = endActiveX - param.bufferX;
    end
    endActiveX = sx-1+NxHT-param.bufferX;
    
    endActiveY=0;
    for tileY = startTileY:endTileY
        load([directoryName,'/ht_',num2str(tileX),'_',num2str(tileY)]);
        load([directoryName,'/ht_dimension_',num2str(tileX),'_',num2str(tileY)])
        
        if tileY==startTileY
            sy = 1;
        else
            sy = endActiveY - param.bufferY;
        end
        
        combined_hologram(sy-1 + (1:NyHT), sx-1 + (1:NxHT)) = combined_hologram(sy-1 + (1:NyHT), sx-1 + (1:NxHT)) + hologramTile;
        endActiveY = sy-1+NyHT-param.bufferY;
        %figure(); imagesc(abs(hologramTile(10:end-14, 10:end-14 ) )); axis equal; axis off; title(['tileX=',num2str(tileX),'   tileY=',num2str(tileY)]);
        %figure(); imagesc(angle(hologramTile(10:end-14, 10:end-14 )  )); axis equal; axis off; title(['tileX=',num2str(tileX),'   tileY=',num2str(tileY)]);
    end
end
end