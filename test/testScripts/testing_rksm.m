clear
clc
clearvars -global

%% testdaten My_rksm

% load any benchmark system
sys = loadSss('fom');
% sys = sys(1,1)
% other models: rail_1357, rail_5177, iss, gyro, building, CDplayer, beam,
%               eady, heat-cont, LF10, random, bips98_606,
%               SpiralInductorPeec, fom

% declare system matices
A = sys.A;
B = sys.B;
C = sys.C;
E = sys.E;

% additional information
m = size(B,2);
p = size(C,1);



%% testing function for several cases
% initialize method
method = 1; % 1 for standard rksm cyclic, reusing shifts, onesided, hermite
            % 2 for standard rksm cyclic, reusing shifts, onesided, hermite, tangential directions (MIMO)
            % 3 for standard rksm cyclic, reusing shifts, twosided, hermite
            % 4 for standard rksm cyclic, reusing shifts, twosided, not hermite
            % 5 for standard rksm cyclic, reusing shifts, twosided, not hermite, tangential
            % 6 for eksm method
            % 7 for standard rksm cyclic, adaptive shifts, onesided, hermite, only for SISO
            % 8 for standard rksm cyclic, adaptive shifts, twosided, hermite, only for SISO
            
% choose computation of residual norm and other options
Opts.residual  = 'residual_lyap';  
%Opts.residual  = 'norm_chol';
Opts.maxiter_rksm = 200;

Opts.maxiter = Opts.maxiter_rksm;
Opts.rctol = 1e-14; 

            
switch method
    case 1
    % mess shifts
%         eqn=struct('A_',sys.A,'E_',sys.E,'B',sys.B,'C',sys.C,'prm',speye(size(sys.A)),'type','N','haveE',sys.isDescriptor);
% 
%         % opts struct: MESS options
%         messOpts.adi=struct('shifts',struct('l0',20,'kp',50,'km',25,'b0',ones(sys.n,1),...
%             'info',1),'maxiter',Opts.maxiter,'restol',0,'rctol',Opts.rctol,...
%             'info',1,'norm','fro');
% 
%         Opts.lse = 'gauss'; 
%         lseType='solveLse';
%         oper = operatormanager(lseType);
%         messOpts.solveLse.lse=Opts.lse;
%         messOpts.solveLse.krylov=0;
% 
%         % get adi shifts
%         [s0,~,~,~,~,~,~,eqn]=mess_para(eqn,messOpts,oper); s0=s0';
        
        %shifts = zeros(1,10);
        %Rt = ones(m,20);        
        %Rt = ones(m,10);
        %Lt = ones(p,10);
        %Lt = ones(p,6);
        %[~, ~, ~, s0, Rt, Lt] = irka(sys,s0,Rt,Lt);
        %[~, ~, ~, s0, Rt, Lt] = irka(sys, shifts,Rt,Lt);
        %Opts.shifts = 'mess';
        %Opts.Cma = C;
        

        Opts.method = 'rksm';
        Opts.shifts = 'mess';
        %Opts.rksmnorm = 'fro';
        Opts.reduction = 'onesided';
        % compute shifts using irka
        shifts = zeros(1,2);
        Rt = ones(m,8);
        Lt = ones(p,8);

        [~, ~, ~, s0, Rt, Lt] = irka(sys, shifts,Rt,Lt);
        % call function
        Opts.shifts = 'mess';
        tic
        [S,R,data_out] = rksm(sys,s0,Opts);
        toc
        %[S,R,data_out] = lyapchol(sys,s0,Opts);
        
    case 2
% mess shifts
        eqn=struct('A_',sys.A,'E_',sys.E,'B',sys.B,'C',sys.C,'prm',speye(size(sys.A)),'type','N','haveE',sys.isDescriptor);

        % opts struct: MESS options
        messOpts.adi=struct('shifts',struct('l0',20,'kp',50,'km',25,'b0',ones(sys.n,1),...
            'info',1),'maxiter',Opts.maxiter,'restol',0,'rctol',Opts.rctol,...
            'info',1,'norm','fro');

        Opts.lse         = 'gauss'; 
        lseType='solveLse';
        oper = operatormanager(lseType);
        messOpts.solveLse.lse=Opts.lse;
        messOpts.solveLse.krylov=0;

        % get adi shifts
        [s0,~,~,~,~,~,~,eqn]=mess_para(eqn,messOpts,oper); s0=s0';
        
        %shifts = zeros(1,10);
        Rt = ones(m,20);        
        %Rt = ones(m,7);
        Lt = ones(p,20);
        %Lt = ones(p,6);
        [~, ~, ~, s0, Rt, Lt] = irka(sys,s0,Rt,Lt);
        %[~, ~, ~, s0, Rt, Lt] = irka(sys, shifts,Rt,Lt);
        Opts.shifts = 'mess';
        Opts.Cma = C;
        tic
        [S,R,data_out] = rksm(A,B,E,s0,Rt,Opts);
        toc
        
    case 3
        % compute shifts using irka
        shifts = zeros(1,10);
        [~, ~, ~, s0] = irka(sys, shifts);
        % call funtion
        tic
        [S,R,data_out] = rksm(A,B,C,E,s0,Opts);
        toc
        %[S,R,data_out] = lyapchol(sys,s0,Opts);
    case 4
        % compute shifts using irka
        shifts = zeros(1,12);
        Rt = ones(m,10);
        Lt = ones(p,10);
        [~, ~, ~, s0, Rt, Lt] = irka(sys, shifts,Rt,Lt);
        s0_inp = s0(1,1:6);
        s0_out = s0(1,7:12);
        tic
        [S,R,data_out] = rksm(A,B,C,E,s0_inp,s0_out,Opts);
        toc
        %[S,R,data_out] = My_rksm(sys,s0_inp,s0_out,Opts);
        
    case 5
        shifts = zeros(1,12);
        Rt = ones(m,12);
        Lt = ones(p,12);
        [~, ~, ~, s0, Rt, Lt] = irka(sys, shifts,Rt,Lt);
        s0_inp = s0(1,1:6);
        s0_out = s0(1,7:12);
        Rt = Rt(1,1:6);
        Lt = Lt(1,1:6);
        tic
        [S,R,data_out] = rksm(A,B,C,E,s0_inp,s0_out,Rt,Lt,Opts);
        toc
        %[S,R,data_out] = My_rksm(sys,s0_inp,s0_out,Rt,Lt,Opts);
        
    case 6
        Opts.method = 'extended';
        s0 = ones(1,2);
        [S,data_out] = rksm(A,B,E,s0,Opts);
        
    case 7
        shifts = zeros(1,10);
        Rt = ones(m,10);
        Lt = ones(p,10);
        [~, ~, ~, s0, Rt, Lt] = irka(sys, shifts,Rt,Lt);
        % Alternative f?r Shifts
        %s0(1,1) = norm(A, 'fro')/condest(A);
        %eigenwerte = -eigs(A,E);
        %s0(1,2) = eigenwerte(1,1);
        
        Opts.shifts = 'adaptive';
        tic
        [S,data_out] = rksm(A,B,E,s0,Opts);
        toc
    case 8
        shifts = zeros(1,2);
        [~, ~, ~, s0] = irka(sys, shifts);
        % Alternative f?r Shifts
        %s0(1,1) = norm(A, 'fro')/condest(A);
        %eigenwerte = -eigs(A,E);
        %s0(1,2) = eigenwerte(1,1);

        Opts.Shifts = 'adaptive';
        tic
        [S,R,data_out] = rksm(A,B,C,E,s0,Opts);
        toc
        
end
V = data_out.V_basis;
W = data_out.W_basis;

%% testing quality of solution
if isempty(W)
    Pr = S'*S;
    P = V*Pr*V';
   % P  = Pr'*Pr;
else
    Pr = W*S*V';
    P  = Pr*Pr';
end
 
Y = A*P*E' + E*P*A' + B*B';
Y_norm = norm(Y);


%% comparing with other methods
% Opts.method = 'hammarling';
% [Shammarling,Rhammarling] = lyapchol(sys,Opts);
% Phammarling = Shammarling*Shammarling';
% Yhammarling = A*Phammarling*E' + E*Phammarling*A' + B*B';
% Yhammarling_norm = norm(Yhammarling);

Opts.method = 'adi';

Opts.rctol = 0;
tic
[Sadi] = lyapchol(sys,Opts);
toc
Padi = Sadi*Sadi';
Yadi = A*Padi*E' + E*Padi*A' + B*B';
Yadi_norm = norm(Yadi);
