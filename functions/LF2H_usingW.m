%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2020.10.29 Jae-Hyeung Park
% 기존에는 LF tile과 Wtile을 input으로 받게 되어있었으나
% 그냥 일반적으로 LF와 W를 input으로 받는 것으로 변경함
% LF와 W의 크기 관계는 그대로 유지함
% 즉 
% size(W) should be size(LF)*M - (M-1) + 2*buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2020.10.29 Jae-Hyeung Park
% startXH와 startXrpm의 indexing
% 20191217 최종정리 버전과
% 20200104 다시정리 버전을 반영
% 따라서 아래와 같이 indexing함 (Nu 짝수 홀수 상관X)
% startXH = floor( (idxTauX-1)/2 ) + floor(- (Nu+1)/4 - NxH_NB/2 + NxH/2) ;
% startXrpm = startXH + floor(Nu/2) - (idxTauX-1) ;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2019.11.13 Jae-Hyeung Park
% Now carrier wave (W) is the input to this function
% Name change:  
%   randomPhaseMx --> Wtile
% size(Wtile) should be size(LFtile)*M - (M-1) + 2*buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2019.10.29 Jae-Hyeung Park
% [구현된 방법 2] 구현
% LFpreprocessing.m
%       - LF (orthographic view)를 tile 별로 저장
%       - 각 LF tile은 가로 세로 1 pixel 씩 overlap됨
% LF2H_tile.m
%       - LF tile 하나를 읽어들여 홀로그램 tile로 만듬
%       - LF tile에서 오른쪽/아래 마지막 한 줄은 interpolation후 처리 X 
%       - (각 tile 간 중복 방지를 위하여)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function H = LF2H_usingW(LF, W, M, bufferX, bufferY, useGpu, verbose)

[NyL, NxL, Nv, Nu] = size(LF);  % 주의(20190813) LF(y,x,v,u) !!

%% input argument size check
Mexp = round(log2(M));
if M~=2^Mexp
    disp(["Error! M should be the integer power of 2"])
end

NxH_NB = M*NxL - (M-1); % Buffer 제외한 홀로그램 샘플 개수
NyH_NB = M*NyL - (M-1); % M-1 은 interp2 때문에 들어간것 
                                                            
NxH = NxH_NB + bufferX*2;  NyH= NyH_NB + bufferY*2;         % Buffer 포함한 홀로그램 샘플 개수

[NyW, NxW] = size(W);
if NxW~=NxH || NyW~=NyH
    disp(['Error! W size should be size(LF)*M - (M-1) + buffer*2'])
end

%% Do Fourier transform of light field first (slide 15 of Hologram synthesis from light field - new idea appended.pptx)
if verbose
    disp('Fourier transform of the light field')
end
% tic
FTlightField = fftshift( fft( ifftshift(LF,3), [], 3), 3);      % 20190816: fft 할 때, ifftshift, fftshift하는 부분을 다시 고치자. 수행 시간 위해 (예전 foveated code 참조)
FTlightField = fftshift( fft( ifftshift(FTlightField,4), [], 4), 4);
% elapsedTime = toc;
% if verbose
%     disp(['Processing time for Fourier transform of the light field =', num2str(elapsedTime),' sec.'])
% end
if useGpu
    FTlightField = gpuArray(FTlightField);
end

%%
if verbose
    disp('add Fourier transform of the light field')
end

% #gpu
H = zeros(NyH, NxH);
if useGpu
    H = gpuArray(H);
    W = gpuArray(W);
end

%%
% tic
doNotProcessRight = 1;  % LF가 tile일 경우를 대비하여 LF tile에서 오른쪽/아래 마지막 한 줄은 interpolation후 처리 X 
doNotProcessBottom = 1; % (각 tile 간 중복 방지를 위하여)

for idxTauX = 1:Nu
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% 20191217 최종정리 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % startXH와 startXrpm의 indexing이 중요
    % idxTauX가 1에서부터 커질때, startXH와 startXrpm은 하나씩 어긋나며 커지게 설정 되어야 함. 
    % 즉, idxTauX =   1,    2,    3,    4, 일 때
    %     startXH =   a,    a,   a+1,  a+1,
    %   startXrpm =   b,   b-1,  b-1,  b-2   이런식.
    
    % 아래는 잘못된 예
    % 즉, idxTauX =   1,    2,    3,    4, 일 때
    %     startXH =   a,    a,   a+1,  a+1,
    %   startXrpm =   b,    b,   b-1,  b-1   이런식.
    
    % hologram에서의 index는 +idxTauX/2 만큼
    % W에서의 index는        -idxTauX/2 만큼 움직이므로
    % 둘 사이에는 항상 idxTauX(=정수) 만큼 차이가 나야함
    
    % 원래 별 생각없이 쓰면
    %startXH = floor( (idxTauX-(Nu+1)/2)/2 ) + floor(-NxH_NB/2 + NxH/2);
    %startXrpm = floor(-(idxTauX-(Nu+1)/2)/2 ) + floor( -NxH_NB/2 + NxH/2);
    %과 같이 되는데 이러면 Nu 값에 따라 될때도 있고 안될때도 있음.
    %Nu에 상관없이 위와 같은 조건 만족위해 아래 코드와 같이 함
    
    % 그리고 아래도 가능하지만 맨 위의 예보다는 결과가 않좋음
    %     idxTauX =   1,    2,    3,    4, 일 때
    %     startXH =   a,    a+1,  a+1,  a+2,
    %   startXrpm =   b,    b,    b-1,  b-1   이런식.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% 20200104 다시 정리 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % 위의 20191217 버전 (이게 large CGH 논문 제출 시 사용 버전)과 같이 했는데
    % occlusion에서 문제 발생
    % 위의 약간 보완하여 그냥
    %     startXH = floor( (idxTauX-1)/2 ) + floor(- (Nu+1)/4 - NxH_NB/2 + NxH/2) ;
    %     startXrpm = startXH + floor(Nu/2) - (idxTauX-1) ;
    % 이런 식으로 하면 startXH와 startXrpm 사이 간격이 언제나 idxTauX만큼 유지되니 OK
    % 좀더 살펴보아야 하지만 현재까지의 관찰사항은
    %   (1) 위의 그대로 하면 occlusion 잘됨
    %   (2) 밑의 4가지로 경우 나누어 평균내는 것도 잘 됨 (occlusion 잘됨)
    %   (3) 따라서 문제 없음. 다만 좀더 이해가 필요한 것
    %   (4) startXH에 임의의 정수를 더해도 잘 됨.
    %   (5) startXrpm에 임의의 정수를 더하면 잘 않됨.
    %   (6) 따라서 startXH와 startXrpm의 상대적차이가 중요함
    %   (7) 현재로는 startXH-startXrpm = -20, -19, ..., 19 인데
    %   (8) startXrpm에 1을 빼서
    %   (9) startXH-startXrpm = -19, -18, ..., 20 으로하면 안됨
    %   (10) 이게 궁굼. 왜그럴까? 즉, Nu가 지금 =40 으로 짝수인데
    %   (11) 이게 홀수인 경우도 다시 따져 보아야 한다는 것.
    %   (12) 아마도 light field fft (fftshift)할 때 짝수일때 인덱싱과 관련있는듯
    %   (13) 아 그렇네. Nu가 짝수일때, fftshift(fft)하면 Nu/2+1에 DC가 오네..
    %   (14) 즉, Nu=4 이면 -2, -1, 0, 1 과 같이 되는 것. 이제 이해가 됨.
    %   (15) 따라서 현재같이 하면 Nu 홀수일때도 문제 없겠음.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    startXH = floor( (idxTauX-1)/2 ) + floor(- (Nu+1)/4 - NxH_NB/2 + NxH/2); 
    endXH = startXH + NxH_NB - 1 - doNotProcessRight ;
        
    startXW = startXH + floor(Nu/2) - (idxTauX-1);  
    endXW = startXW + NxH_NB -1 - doNotProcessRight;
        
    for idxTauY = 1:Nv
        startYH = floor( (idxTauY-1)/2 ) + floor( - (Nv+1)/4 - NyH_NB/2 + NyH/2);
        endYH = startYH + NyH_NB - 1 - doNotProcessBottom;
                
        startYW = startYH + floor(Nv/2) - (idxTauY-1) ;
        endYW = startYW + NyH_NB -1 - doNotProcessBottom;
        
        %%%% 20190816 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % M 배로 interpolation 
        common = interp2(FTlightField(:,:,idxTauY, idxTauX),Mexp);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% 20191029 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % LF tile에서 오른쪽/아래 마지막 한 줄은 interpolation후 처리 X
        common = common(1:end-doNotProcessBottom, 1:end-doNotProcessRight);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                                                                             
        if mod(idxTauX,2)==1 && mod(idxTauY,2)==1
            H(startYH:endYH, startXH:endXH) = H(startYH:endYH, startXH:endXH) + common.*W(startYW:endYW, startXW:endXW); 
            
        elseif mod(idxTauX,2)==1 && mod(idxTauY,2)==0
            common_smooth = 0.5*conv2(common, [1;1]);
            H(startYH:(endYH+1), startXH:endXH) = H(startYH:(endYH+1), startXH:endXH) + common_smooth.*W(startYW:(endYW+1), startXW:endXW);
            
        elseif mod(idxTauX,2)==0 && mod(idxTauY,2)==1
            common_smooth = 0.5*conv2(common, [1,1]);
            H(startYH:endYH, startXH:(endXH+1)) = H(startYH:endYH, startXH:(endXH+1)) + common_smooth.*W(startYW:endYW, startXW:(endXW+1));
            
        else
            common_smooth = 0.25*conv2(common,[1,1;1,1]);
            H(startYH:(endYH+1), startXH:(endXH+1)) = H(startYH:(endYH+1), startXH:(endXH+1)) + common_smooth.*W(startYW:(endYW+1), startXW:(endXW+1));
        end
    end
    
    if verbose
        if mod(idxTauX,3)==0
            disp([num2str(100*idxTauX/Nu,'%3.1f'),'% completed'])
        end
    end
    
end
% elapsedTime = toc;
% if verbose
%     disp(['Processing time for add Fourier transform of the light field =', num2str(elapsedTime),' sec.'])
% end
if useGpu
    H = gather(H);
end
end
