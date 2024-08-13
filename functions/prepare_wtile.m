function prepare_wtile(directoryName, fileNameHeader, param, CWtype, lambda)

NxWTarray= zeros(param.NtileX,1);
NyWTarray = zeros(param.NtileY,1);

startIdxGlobalX = zeros(param.NtileX,1);  % start index in global considering param.overlapX pixel LF overlapping
startIdxGlobalY = zeros(param.NtileY,1);  % start index in global considering param.overlapY pixel LF overlapping

for tileX = 1 : param.NtileX
    for tileY = 1 : param.NtileY
        idxFile=1;
        temp = imread([directoryName,'/LF_tiles/tile_', num2str(tileX),'_',num2str(tileY),'/', fileNameHeader, num2str(idxFile,'%04d'),'.png']);
        [NyL, NxL, ~] = size(temp);
        clear temp
         
        NxH_NB = param.M*NxL - (param.M-1); % Buffer
        NyH_NB = param.M*NyL - (param.M-1);
        
        NxWT = NxH_NB + 2*param.bufferX;
        NyWT = NyH_NB + 2*param.bufferY;
        
        NxWTarray(tileX) = NxWT;
        NyWTarray(tileY) = NyWT;
        
        if tileX == 1
            startIdxGlobalX(1) = 1;
        else
            startIdxGlobalX(tileX) = startIdxGlobalX(tileX-1) + NxWTarray(tileX-1) - param.overlapX - 2*param.bufferX; % param.overlapX ?”½???”© LF overlapping?´ ?žˆ?œ¼?‹ˆê¹?
        end
        if tileY == 1
            startIdxGlobalY(1) = 1;
        else
            startIdxGlobalY(tileY) = startIdxGlobalY(tileY-1) + NyWTarray(tileY-1) - param.overlapY - 2*param.bufferY; % param.overlapY ?”½???”© LF overlapping?´ ?žˆ?œ¼?‹ˆê¹?
        end
    end
end

NxH = startIdxGlobalX(param.NtileX) + NxWTarray(param.NtileX) - 1;
NyH = startIdxGlobalY(param.NtileY) + NyWTarray(param.NtileY) - 1;

%% W
mkdir([directoryName, '/W_tiles']);
if strcmp(CWtype, 'random')
    %%%%  W = random complex %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    for tileX = 1:param.NtileX
        for tileY = 1:param.NtileY
           NxWT = NxWTarray(tileX);
            NyWT = NyWTarray(tileY);
            
            NxRP = NxWT - 2*param.bufferX; % = NxH_NB
            NyRP = NyWT - 2*param.bufferY; % = NyH_NB

            aa = rand(NyRP, NxRP).*exp(1j*2*pi*rand(NyRP, NxRP));
            bb = zeros(NyWT, NxWT);
            bb( (1:NyRP)+floor(-NyRP/2+NyWT/2), (1:NxRP)+floor(-NxRP/2+NxWT/2) ) = aa;
            clear aa;
            
            Wtile = myifft2(bb); 
            clear bb;
            
            Wtile = single(Wtile);
            
            if tileX>1
                prevWT = load([directoryName,'/W_tiles/wt_',num2str(tileX-1),'_',num2str(tileY)],'Wtile');
                Wtile(:, 1:(param.bufferX*2+1)) = prevWT.Wtile(:, (end-param.bufferX*2):end);
            end
            if tileY>1
                prevWT = load([directoryName,'/W_tiles/wt_',num2str(tileX),'_',num2str(tileY-1)],'Wtile');
                Wtile(1:(param.bufferY*2+1), :) = prevWT.Wtile((end-param.bufferY*2):end, :);
            end
            
            save([directoryName,'/W_tiles/', 'wt_',num2str(tileX),'_',num2str(tileY)],'Wtile');
            save([directoryName,'/W_tiles/', 'wt_dimension_',num2str(tileX),'_',num2str(tileY)],'NxWT','NyWT');
            disp(['W for tileX=',num2str(tileX),'  tileY=',num2str(tileY),' has just been created.'])
        end
    end
elseif strcmp(CWtype, 'plane')
    %%%%  W = plane wave (CWspatialFreqX, CWspatialFreqY) %%%%%%%%%%%%%%%%%%%%%%%%%%% 
    CWspatialFreqX = (1/(param.dxH*NxH))*0;
    CWspatialFreqY = (1/(param.dyH*NyH))*0;
    
    for tileX = 1:param.NtileX
        for tileY = 1:param.NtileY
            NxWT = NxWTarray(tileX);
            NyWT = NyWTarray(tileY);
            
            [xx,yy] = meshgrid( ((startIdxGlobalX(tileX)-1 + (1:NxWT))-(NxH+1)/2)*param.dxH,  ((startIdxGlobalY(tileY)-1 + (1:NyWT)) - (NyH+1)/2)*param.dyH );
            Wtile = exp(1j*2*pi*( CWspatialFreqX*xx + CWspatialFreqY*yy ));

            save([directoryName,'/W_tiles/', 'wt_',num2str(tileX),'_',num2str(tileY)],'Wtile');
            save([directoryName,'/W_tiles/', 'wt_dimension_',num2str(tileX),'_',num2str(tileY)],'NxWT','NyWT');
            disp(['W for tileX=',num2str(tileX),'  tileY=',num2str(tileY),' has just been created.'])
        end
    end
elseif strcmp(CWtype, 'spherical')
    %%%%  W = spherical wave focal length = CWf %%%%%%%%%%%%%%%%%%%%%%%%%%% 
    CWf = 3e-2;

    for tileX = 1:param.NtileX
        for tileY = 1:param.NtileY
            NxWT = NxWTarray(tileX);
            NyWT = NyWTarray(tileY);
            
            [xx,yy] = meshgrid( ((startIdxGlobalX(tileX)-1 + (1:NxWT))-(NxH+1)/2)*param.dxH,  ((startIdxGlobalY(tileY)-1 + (1:NyWT)) - (NyH+1)/2)*param.dyH );
            Wtile = exp(1j*2*pi*(1/(2*lambda*CWf))*( xx.^2 + yy.^2 ));
            
            save([directoryName,'/W_tiles/', 'wt_',num2str(tileX),'_',num2str(tileY)],'Wtile');
            save([directoryName,'/W_tiles/', 'wt_dimension_',num2str(tileX),'_',num2str(tileY)],'NxWT','NyWT');
            disp(['W for tileX=',num2str(tileX),'  tileY=',num2str(tileY),' has just been created.'])
        end
    end
end

end