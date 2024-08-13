clear all
clc
addpath('./functions')

%% Light field
fileNameHeader = 'sockets_jhpark_';
directoryName = './sockets'; 
param = load_parameters_from_txt([directoryName, '/parameter_sockets.txt']);
param = cal_derived_parameters(param);
display(param)

%% Light field tiling
disp('Light field tiling')
prepare_lftile(directoryName, fileNameHeader, param);

tic;
%%
for idxColor=1:3
    switch idxColor
        case 1
            lambda = param.lambdaR;
        case 2
            lambda = param.lambdaG;
        case 3
            lambda = param.lambdaB;
    end
    
    %% Wtile
    disp('Wtile calcualtion')
    CWtype = 'random';
    prepare_wtile(directoryName, fileNameHeader, param, CWtype, lambda)
    
    %%
    disp('Hologram calculation')
    WtileDirectoryName = 'W_tiles';
    is_mask = 0;
    useGpu = 1; verbose=1;
    nhlfh_Wtile(directoryName, fileNameHeader, is_mask, idxColor, WtileDirectoryName, param, useGpu, verbose);
    
    %%
    disp('Combining Hologram tiles')
    startTileX=1; endTileX=2;
    startTileY=1; endTileY=2;
    hologram = combineHtiles([directoryName,'/NHLFH_tiles'], startTileX, endTileX, startTileY, endTileY, param);
    
    %% save
    switch idxColor
        case 1
            hologramR = hologram;
            save('hologramR', 'hologramR');
        case 2
            hologramG = hologram;
            save('hologramG', 'hologramG');
        case 3
            hologramB = hologram;
            save('hologramB', 'hologramB');
    end
    
end
time = toc;
disp(['CGH completed: ', num2str(time), ' sec.'])

%% Reconstruction
load('hologramR');
hologram = hologramR; clear hologramR;
load('hologramG');
hologram(:,:,2) = hologramG; clear hologramG;
load('hologramB');
hologram(:,:,3) = hologramB; clear hologramB;
lambda = [param.lambdaR, param.lambdaG, param.lambdaB];

%%
for zRec = [-0.75, 0.5]*1e-3
recColor = zeros(size(hologram));
for idxColor=1:3
    [rec,dummy_du,dummy_dv, max_phase_step] = FresnelPropagation_as(hologram(:,:,idxColor), param.dxH, param.dyH, zRec, lambda(idxColor));
    recColor(:,:,idxColor) = abs(rec);
end
figure(); imshow(uint8(255*recColor/max(recColor(:))))
end