function param = cal_derived_parameters_nocolor(param)
%%%%%%%%%%%%%%%%%%%%%
% Nu,Nv compensation for color processing
% du, dv are kept the same for all colors
% param.uvInterpR = param.lambdaR / param.lambdaR;
% param.uvInterpG = param.lambdaG / param.lambdaR;
% param.uvInterpB = param.lambdaB / param.lambdaR;
param.uvInterpCommon = 1;
%%%%%%%%%%%%%%%%%%%%%%

param.M = 2^param.Mexp; 

param.Nu = ceil( param.NuFile / param.uvInterpCommon ); % color    
param.Nv = ceil( param.NvFile / param.uvInterpCommon );  

param.dxL = param.dxFile; 
param.dyL = param.dyFile;                   % LF data spatial sampling pitch
param.z = [param.zFileMin, param.zFileMax];

param.dxH = param.dxL/param.M;
param.dyH = param.dyL/param.M;

param.du = (1/param.dxH)/param.Nu;
param.dv = (1/param.dyH)/param.Nv;          % u ==> sin(theta)/lambda

param.bufferX = floor(param.Nu/2)+1;
param.bufferY = floor(param.Nv/2)+1;

%%%%%%%%%%
NxTile_minus_overlap = param.NxTile - param.overlapX;
NyTile_minus_overlap = param.NyTile - param.overlapY;

NtileX = ceil(param.NxFile / NxTile_minus_overlap);
if param.NxFile - (NtileX-1)*NxTile_minus_overlap < 2
    NtileX = NtileX-1;
end

NtileY = ceil(param.NyFile / NyTile_minus_overlap);
if param.NyFile - (NtileY-1)*NyTile_minus_overlap < 2
    NtileY = NtileY-1;
end

param.NtileX = NtileX;
param.NtileY = NtileY;
end