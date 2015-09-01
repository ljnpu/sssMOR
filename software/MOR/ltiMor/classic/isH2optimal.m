function isH2optimal = isH2optimal(sys,sysr,s0,Opts)
% ISH2OPTIMAL - evaluate Maier-Luenberger conditions for H2-optimality
%
% Syntax:
%   ISH2OPTIMAL(sys,sysr,s0)
%   ISH2OPTIMAL(sys,sysr,s0,Opts)
%   isH2optimal = ISH2OPTIMAL(sys,sysr,s0)
%
% Description:
%   This function evaluates the Maier-Luenberger conditions for
%   H2-optimality according to the input data, i.e. 
%   - sys, the high fidelity model
%   - sysr, the reduced order model
%   - s0,  the shifts at which sysr interpolates sys
%
%   Following conditions must be met:
%   a) the reduced eigenvalues are the mirror images of the shifts
%   b) two moments are matched at each shift
%
%   Then sysr is said to be a locally H2-optimal approximation of sys
%
%
% See also:
%   MOMENTS, IRKA, SPARK, EIG
%
% References:
%   [1] Gugercin et al. (2008), H2 model reduction for large-scale linear
%       dynamical systems
%
% ------------------------------------------------------------------
%   This file is part of sssMOR, a Sparse State Space, Model Order
%   Reduction and System Analysis Toolbox developed at the Institute 
%   of Automatic Control, Technische Universitaet Muenchen.
%   For updates and further information please visit www.rt.mw.tum.de
%   For any suggestions, submission and/or bug reports, mail us at
%                     -> sssMOR@rt.mw.tum.de <-
% ------------------------------------------------------------------
% Authors:      Alessandro Castagnotto
% Last Change:  31 Aug 2015
% Copyright (c) 2015 Chair of Automatic Control, TU Muenchen
% ------------------------------------------------------------------

%%  Parse input and initialize

%   Get execution parameters
Def.tol = 1e-3;
if ~exist('Opts','var') || isempty(Opts)
    Opts = Def;
else
    Opts = parseOpts(Opts,Def);
end

%   Predefine variables
isH2optimal = 0; %initialize
%%  Computations 
if norm(setdiffVec(s0',-conj(eig(sysr))))/norm(s0)<=Opts.tol
    %   reduced eigenvalues are mirror images of shifts
    for iShift = 1:length(s0)
        m   = moments(sys,s0(iShift),2);
        mr  = moments(sysr,s0(iShift),2);
        if norm(m-mr)/norm(m)> Opts.tol
            % moments do not match
            return
        end
    end
    %   if you reached this point, all verifications passed!
    isH2optimal = 1;
end