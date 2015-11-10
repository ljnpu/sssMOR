classdef testCure < matlab.unittest.TestCase
    
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
        function testCureDef(testCase)
            for i=1:length(testCase.sysCell)
                sys=testCase.sysCell{i};
                badBenchmarks = {'LF10.mat','beam.mat','random.mat',...
                    'SpiralInductorPeec.mat'};
                
                if ~any(strcmp(sys.Name,badBenchmarks))
                disp(sys)
                if ~sys.isSiso, sys = sys(1,1); end
                
                % run cure (default options)
                warning off
                cure(sys);
                warning on 
                
                % no verification available for this
                end
            end
        end
        function testCureNonDef(testCase)
            sys = loadSss('iss');
            disp(sys)
            if ~sys.isSiso, sys = sys(1,1); end
            [~, w] = freqresp(sys);

            % run cured spark with non default values
            Opts.cure = struct('fact','W',...
                          'init','slm',...
                          'stop','h2Error',...
                          'stopval',norm(sys)*1e-1,...
                          'verbose', 1,...
                          'test', 1,...
                          'gif',1,...
                          'maxIter',10);
            Opts.warn =1;
            Opts.w = w;

            warning off
            cure(sys,Opts);
            warning on
            close all
        end
        function testCuredIrka(testCase)
            sys = loadSss('rail_1357');
            disp(sys)
            if ~sys.isSiso, sys = sys(1,1); end

            % run cured spark with non default values
            Opts.cure = struct('redfun','irka',...
                          'fact','V',...
                          'init','slm',...
                          'stopval',20,...
                          'nk', 4);
            warning off
            cure(sys,Opts);
            
            Opts.cure = struct('redfun','irka',...
                          'fact','W',...
                          'init','slm',...
                          'stopval',20,...
                          'nk', 4);
            cure(sys,Opts);
            warning on
        end
        function testCuredRk(testCase)
            sys = loadSss('eady');
            disp(sys)
            if ~sys.isSiso, sys = sys(1,1); end
            warning off
            % run cured spark with non default values
            Opts.cure = struct('redfun','rk+pork',...
                          'fact','V',...
                          'init','slm',...
                          'stopval',20,...
                          'nk', 5);
            cure(sys,Opts);
            Opts.cure = struct('redfun','rk+pork',...
                          'fact','W',...
                          'init','slm',...
                          'stopval',20,...
                          'nk', 5);
            cure(sys,Opts);
            warning on
        end
    end
end