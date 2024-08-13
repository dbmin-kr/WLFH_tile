function [param] = load_parameters_from_txt(fileName)
fid = fopen(fileName);
allParam = textscan(fid,'%s%f','CommentStyle', '%');

%% Original light field
% NxFile, NyFile 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'NxFile');   
param.NxFile = allParam{2}(rightRow);
if isempty(param.NxFile)
    disp('NxFile is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'NyFile');   
param.NyFile = allParam{2}(rightRow);
if isempty(param.NyFile)
    disp('NyFile is missing in the parameter txt file')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% NuFile, NvFile 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'NuFile');   
param.NuFile = allParam{2}(rightRow);
if isempty(param.NuFile)
    disp('NuFile is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'NvFile');   
param.NvFile = allParam{2}(rightRow);
if isempty(param.NvFile)
    disp('NvFile is missing in the parameter txt file')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% dxFile, dyFile 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'dxFile');   
param.dxFile = allParam{2}(rightRow);
if isempty(param.dxFile)
    disp('dxFile is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'dyFile');   
param.dyFile = allParam{2}(rightRow);
if isempty(param.dyFile)
    disp('dyFile is missing in the parameter txt file')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% zFileMin, zFileMax 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'zFileMin');   
param.zFileMin = allParam{2}(rightRow);
if isempty(param.zFileMin)
    disp('zFileMin is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'zFileMax');   
param.zFileMax = allParam{2}(rightRow);
if isempty(param.zFileMax)
    disp('zFileMax is missing in the parameter txt file')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% lambdaR, lambdaG, lambdaB 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'lambdaR');   
param.lambdaR = allParam{2}(rightRow);
if isempty(param.lambdaR)
    disp('lambdaR is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'lambdaG');   
param.lambdaG = allParam{2}(rightRow);
if isempty(param.lambdaG)
    disp('lambdaG is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'lambdaB');   
param.lambdaB = allParam{2}(rightRow);
if isempty(param.lambdaB)
    disp('lambdaB is missing in the parameter txt file')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Magnification (affects Wtile, hologram, ...)
% Mexp -------->   M = 2^Mexp
rightRow = strcmp(allParam{1},'Mexp');   
param.Mexp = allParam{2}(rightRow);
if isempty(param.Mexp)
    disp('Mexp is missing in the parameter txt file')
end


%% Tiling
% NxTile, NyTile 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'NxTile');   
param.NxTile = allParam{2}(rightRow);
if isempty(param.NxTile)
    disp('NxTile is missing in the parameter txt file')
end

rightRow = strcmp(allParam{1},'NyTile');   
param.NyTile = allParam{2}(rightRow);
if isempty(param.NyTile)
    disp('NyTile is missing in the parameter txt file')
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% overlapX, overlapY 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rightRow = strcmp(allParam{1},'overlapX');   
param.overlapX = allParam{2}(rightRow);
if isempty(param.overlapX)
    disp('overlapX is missing in the parameter txt file')
    disp('default value overlapX=1 will be used')
    param.overlapX = 1;
end

rightRow = strcmp(allParam{1},'overlapY');   
param.overlapY = allParam{2}(rightRow);
if isempty(param.overlapY)
    disp('overlapY is missing in the parameter txt file')
    disp('default value overlapY=1 will be used')
    param.overlapY = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
fclose(fid);
%param
end
