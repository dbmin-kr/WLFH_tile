%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2020.10.29 Jae-Hyeung Park
% �������� LF tile�� Wtile�� input���� �ް� �Ǿ��־�����
% �׳� �Ϲ������� LF�� W�� input���� �޴� ������ ������
% LF�� W�� ũ�� ����� �״�� ������
% �� 
% size(W) should be size(LF)*M - (M-1) + 2*buffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2020.10.29 Jae-Hyeung Park
% startXH�� startXrpm�� indexing
% 20191217 �������� ������
% 20200104 �ٽ����� ������ �ݿ�
% ���� �Ʒ��� ���� indexing�� (Nu ¦�� Ȧ�� ���X)
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
% [������ ��� 2] ����
% LFpreprocessing.m
%       - LF (orthographic view)�� tile ���� ����
%       - �� LF tile�� ���� ���� 1 pixel �� overlap��
% LF2H_tile.m
%       - LF tile �ϳ��� �о�鿩 Ȧ�α׷� tile�� ����
%       - LF tile���� ������/�Ʒ� ������ �� ���� interpolation�� ó�� X 
%       - (�� tile �� �ߺ� ������ ���Ͽ�)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function H = LF2H_usingW(LF, W, M, bufferX, bufferY, useGpu, verbose)

[NyL, NxL, Nv, Nu] = size(LF);  % ����(20190813) LF(y,x,v,u) !!

%% input argument size check
Mexp = round(log2(M));
if M~=2^Mexp
    disp(["Error! M should be the integer power of 2"])
end

NxH_NB = M*NxL - (M-1); % Buffer ������ Ȧ�α׷� ���� ����
NyH_NB = M*NyL - (M-1); % M-1 �� interp2 ������ ���� 
                                                            
NxH = NxH_NB + bufferX*2;  NyH= NyH_NB + bufferY*2;         % Buffer ������ Ȧ�α׷� ���� ����

[NyW, NxW] = size(W);
if NxW~=NxH || NyW~=NyH
    disp(['Error! W size should be size(LF)*M - (M-1) + buffer*2'])
end

%% Do Fourier transform of light field first (slide 15 of Hologram synthesis from light field - new idea appended.pptx)
if verbose
    disp('Fourier transform of the light field')
end
% tic
FTlightField = fftshift( fft( ifftshift(LF,3), [], 3), 3);      % 20190816: fft �� ��, ifftshift, fftshift�ϴ� �κ��� �ٽ� ��ġ��. ���� �ð� ���� (���� foveated code ����)
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
doNotProcessRight = 1;  % LF�� tile�� ��츦 ����Ͽ� LF tile���� ������/�Ʒ� ������ �� ���� interpolation�� ó�� X 
doNotProcessBottom = 1; % (�� tile �� �ߺ� ������ ���Ͽ�)

for idxTauX = 1:Nu
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% 20191217 �������� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % startXH�� startXrpm�� indexing�� �߿�
    % idxTauX�� 1�������� Ŀ����, startXH�� startXrpm�� �ϳ��� ��߳��� Ŀ���� ���� �Ǿ�� ��. 
    % ��, idxTauX =   1,    2,    3,    4, �� ��
    %     startXH =   a,    a,   a+1,  a+1,
    %   startXrpm =   b,   b-1,  b-1,  b-2   �̷���.
    
    % �Ʒ��� �߸��� ��
    % ��, idxTauX =   1,    2,    3,    4, �� ��
    %     startXH =   a,    a,   a+1,  a+1,
    %   startXrpm =   b,    b,   b-1,  b-1   �̷���.
    
    % hologram������ index�� +idxTauX/2 ��ŭ
    % W������ index��        -idxTauX/2 ��ŭ �����̹Ƿ�
    % �� ���̿��� �׻� idxTauX(=����) ��ŭ ���̰� ������
    
    % ���� �� �������� ����
    %startXH = floor( (idxTauX-(Nu+1)/2)/2 ) + floor(-NxH_NB/2 + NxH/2);
    %startXrpm = floor(-(idxTauX-(Nu+1)/2)/2 ) + floor( -NxH_NB/2 + NxH/2);
    %�� ���� �Ǵµ� �̷��� Nu ���� ���� �ɶ��� �ְ� �ȵɶ��� ����.
    %Nu�� ������� ���� ���� ���� �������� �Ʒ� �ڵ�� ���� ��
    
    % �׸��� �Ʒ��� ���������� �� ���� �����ٴ� ����� ������
    %     idxTauX =   1,    2,    3,    4, �� ��
    %     startXH =   a,    a+1,  a+1,  a+2,
    %   startXrpm =   b,    b,    b-1,  b-1   �̷���.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%% 20200104 �ٽ� ���� %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ���� 20191217 ���� (�̰� large CGH �� ���� �� ��� ����)�� ���� �ߴµ�
    % occlusion���� ���� �߻�
    % ���� �ణ �����Ͽ� �׳�
    %     startXH = floor( (idxTauX-1)/2 ) + floor(- (Nu+1)/4 - NxH_NB/2 + NxH/2) ;
    %     startXrpm = startXH + floor(Nu/2) - (idxTauX-1) ;
    % �̷� ������ �ϸ� startXH�� startXrpm ���� ������ ������ idxTauX��ŭ �����Ǵ� OK
    % ���� ���캸�ƾ� ������ ��������� ����������
    %   (1) ���� �״�� �ϸ� occlusion �ߵ�
    %   (2) ���� 4������ ��� ������ ��ճ��� �͵� �� �� (occlusion �ߵ�)
    %   (3) ���� ���� ����. �ٸ� ���� ���ذ� �ʿ��� ��
    %   (4) startXH�� ������ ������ ���ص� �� ��.
    %   (5) startXrpm�� ������ ������ ���ϸ� �� �ʵ�.
    %   (6) ���� startXH�� startXrpm�� ��������̰� �߿���
    %   (7) ����δ� startXH-startXrpm = -20, -19, ..., 19 �ε�
    %   (8) startXrpm�� 1�� ����
    %   (9) startXH-startXrpm = -19, -18, ..., 20 �����ϸ� �ȵ�
    %   (10) �̰� �ñ�. �ֱ׷���? ��, Nu�� ���� =40 ���� ¦���ε�
    %   (11) �̰� Ȧ���� ��쵵 �ٽ� ���� ���ƾ� �Ѵٴ� ��.
    %   (12) �Ƹ��� light field fft (fftshift)�� �� ¦���϶� �ε��̰� �����ִµ�
    %   (13) �� �׷���. Nu�� ¦���϶�, fftshift(fft)�ϸ� Nu/2+1�� DC�� ����..
    %   (14) ��, Nu=4 �̸� -2, -1, 0, 1 �� ���� �Ǵ� ��. ���� ���ذ� ��.
    %   (15) ���� ���簰�� �ϸ� Nu Ȧ���϶��� ���� ������.
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
        % M ��� interpolation 
        common = interp2(FTlightField(:,:,idxTauY, idxTauX),Mexp);
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%% 20191029 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % LF tile���� ������/�Ʒ� ������ �� ���� interpolation�� ó�� X
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
