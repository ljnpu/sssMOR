classdef testPork < matlab.unittest.TestCase
    
    properties
         sysCell;
    end
 
    methods(TestMethodSetup)
        function getBenchmarks(testCase)
            % change path
            Path = pwd; %original
            
            %insert path of local benchmark folder
            %the directory "benchmark" is in sssMOR
            p = mfilename('fullpath'); k = strfind(p, 'test\'); 
            pathBenchmarks = [p(1:k-1),'benchmarks'];
            cd(pathBenchmarks);

            % load files
            files = dir('*.mat'); 
            testCase.sysCell=cell(1,length(files));
%             warning('off','sssMOR:loadSss:2ndOrder')
            warning off
            for i=1:length(files)
                testCase.sysCell{i} = loadSss(files(i).name);
            end
            warning on
%             warning('on','loadSss:2ndOrder')

            % change path back
            cd(Path);
        end
    end
    
    %Test functions
    methods (Test)  
        function testPorkV(testCase)
            for i=1:length(testCase.sysCell)
                sys=testCase.sysCell{i};
                badBenchmarks = {'LF10.mat','beam.mat','random.mat',...
                    'SpiralInductorPeec.mat','heat-cont.mat','rail_1357.mat'};
                
                if ~any(strcmp(sys.Name,badBenchmarks))
                    disp(sys)
                % get irka shifts and tangential directions
                n = 10; r = ones(sys.m,n); l = ones(sys.p,n);
                sysrIrka = irka(sys, zeros(1,n),r,l);
                
                if sys.isSiso || sys.isSimo
                    s0 = -(conj(eig(sysrIrka))).';
                    [sysr, V] = rk(sys,s0);
                else
                    Opts.rType = 'dir';[r,p] = residue (sysrIrka,Opts);
                    s0 = -(conj(p)); r = r{2}.'; 
                    [sysr, V] = rk(sys,s0,r);
                end              
                
                % get (S,R)
                [R, S] = getSylvester(sys, sysr, V);
                
                % perform pseudo-optimal reduction
                [Ar,Br,Cr,Er] = porkV(V,S,R,sys.C);
                sysr = sss(Ar,Br,Cr,sys.D,Er);
                
                actSolution={sysr,sys,s0,r};
                
                verification (testCase, actSolution);
                end
            end
        end
        function testPorkW(testCase)
            for i=1:length(testCase.sysCell)
                sys=testCase.sysCell{i};
                badBenchmarks = {'LF10.mat','beam.mat','random.mat',...
                    'SpiralInductorPeec.mat','heat-cont.mat'};
                
                if ~any(strcmp(sys.Name,badBenchmarks))
                    disp(sys)
                % get irka shifts and tangential directions
                n = 10; r = ones(sys.m,n); l = ones(sys.p,n);
                sysrIrka = irka(sys, zeros(1,n),r,l);
                
                if sys.isSiso || sys.isSimo
                    s0 = -(conj(eig(sysrIrka))).';
                    [sysr, ~, W] = rk(sys,[],s0);
                else
                    Opts.rType = 'dir';[r,p] = residue (sysrIrka,Opts);
                    s0 = -(conj(p)); l = r{1}; 
                    [sysr, ~, W] = rk(sys,[],s0,[],l);
                end              
                
                % get (S,L)
                warning off
                [L, S] = getSylvester(sys, sysr, W, 'W');
                warning on
                
                % perform pseudo-optimal reduction
                [Ar,Br,Cr,Er] = porkW(W,S,L.',sys.B);
                sysr = sss(Ar,Br,Cr,sys.D,Er);
                
                actSolution={sysr.',sys.',s0, l}; %pass dual system
                
                verification (testCase, actSolution);
                end
            end
        end
    end
end
    
function [] = verification (testCase, actSolution)
          sysr = actSolution{1}; sys = actSolution{2}; 
          s0 = actSolution{3}; r = actSolution{4};
          % sizes
          verifySize(testCase, sysr.a, [length(s0),length(s0)], 'Size not matching');
          % is Er == I?
          verifyEqual(testCase, sysr.e , speye(length(s0)), 'Er~= I');
          % does Ar have eigenvalues at the mirror images of the shifts?
           verifyEqual(testCase, cplxpair(eig(sysr)) , cplxpair(-s0.') ,...
               'RelTol', 1e-3, 'Eigenvalues do not match');
           % do the moments match?
           for iS = 1:length(s0)
                verifyEqual(testCase, moments(sys,s0(iS),1)*r(:,iS) , ...
                    moments(sysr,s0(iS),1)*r(:,iS), 'RelTol',1e-3, 'Moments do not match');
           end
end