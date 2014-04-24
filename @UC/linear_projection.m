function [yp, m, b] = linear_projection(x,y,xp)
    % This function takes an x vector and y vector, and their associated 
    % uncertainty vectors, and calculates the uncertainty at a given 
    % extrapolated or interpolated point using a linear fit.
    % All input vectors must be the same length.
    %
    %  by YuXin Yang and Tyler Voskuilen, October 2011
    %
    % Inputs:
    %     x  Vector of x UC values
    %     y  Vector of y UC values
    %    xp  Projection point
    %
    % Outputs:
    %   yp   Structure containing .value and .err for the
    %          projected point
    %     m   Structure containing .value and .err for 
    %          the linear fit slope
    %     b   Structure containing .value and .err for
    %          the linear fit intercept
    
    
    % Copyright (c) 2014, Tyler Voskuilen
    % All rights reserved.
    % 
    % Redistribution and use in source and binary forms, with or without 
    % modification, are permitted provided that the following conditions are 
    % met:
    % 
    %     * Redistributions of source code must retain the above copyright 
    %       notice, this list of conditions and the following disclaimer.
    %     * Redistributions in binary form must reproduce the above copyright 
    %       notice, this list of conditions and the following disclaimer in 
    %       the documentation and/or other materials provided with the 
    %       distribution
    %       
    % THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
    % IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
    % THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  
    % PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
    % CONTRIBUTORS BE  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
    % EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
    % PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
    % PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
    % LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
    % NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
    % SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


% Check that all inputs are present ======================================
if nargin ~= 3
    error('Incorrect number of inputs');
end

% Check that the vectors are the same length =============================
n = length(x);
if length(y) ~= n
    error('All input vectors must be the same length');
end

if ~isa(x,'UC')
    x = UC(x,0,'x');
end

if ~isa(y,'UC')
    y = UC(y,0,'y');
end

if ~isa(xp,'UC')
    xp = UC(xp,0,'xp');
end

%Perform x shift to set 0 at xp
x = x - xp.Value;
    
% PERFORM LINEAR FIT =====================================================
% Future improvement could allow higher order polyfit, however the later
% uncertainty analysis would become considerably more complicated
[P, S] = polyfit([x.Value], [y.Value], 1);

% FIND STATISTICAL ERROR IN PROJECTED VALUE ==============================
%  This is related to how 'good' the linear fit to X and Y values is,
%  but does not take into account the uncertainty in the values of X and Y
%  e_yp_stat is 1 standard deviation according to the MATLAB documentation.
%  It does not take the number of points into consideration, with more
%  points, this value approaches the standard deviation of the original
%  dataset.
%
%  This takes the standard deviation and calculates the 95% CI of the mean
%  using the Student's t-distribution.
[yp_v, e_yp_stdev] = polyval(P,0,S);
t_val = tinv(0.975,length(x)-1);
e_yp_stat = t_val .* e_yp_stdev ./ sqrt(length(x));

% FIND UNCERTAINTY IN yp DUE TO UNCERTAINTY IN X AND Y ===================
Sx = sum([x.Value]);
Sy = sum([y.Value]);
Sxy = sum([x.Value].*[y.Value]);
Sxx = sum([x.Value].^2);

%y = mx+b
m_v = P(1);
b_v = P(2);

% b = (Sy*Sxx - Sx*Sxy)/(n*Sxx-Sx^2) = g/h
dbdy = (Sxx - [x.Value].*Sx) ./ (n.*Sxx - Sx.^2);

h = n.*Sxx - Sx.^2;
g = Sy.*Sxx - Sx.*Sxy;
hp = 2*n.*[x.Value] - 2.*Sx;          %dh/dx
gp = 2.*Sy.*[x.Value] - Sxy - [y.Value].*Sx;  %dg/dx
dbdx = (h.*gp - hp.*g)./h.^2;

E = [dbdy.*[y.Err] dbdx.*[x.Err]];


%Assume the points are self-correlated
%This has to be redone with a sparse matrix or a loop...
Rc = eye(length(x)+length(y));
%Rc(1:length(y),1:length(y))=0;
%Rc(length(y)+1:length(x)+length(y),length(y)+1:length(x)+length(y))=0;



b_e = sqrt(E*Rc*E');
    
% m = (n*Sxy - Sx*Sy)/(n*Sxx-Sx^2) = f/h
dmdy = (n*[x.Value] - Sx)/(n*Sxx-Sx^2);

f = n.*Sxy - Sx.*Sy;
fp = n.*[y.Value] - Sy; %df/dx
dmdx = (h.*fp - hp.*f)./h.^2;

% Uncertainty in m and b
m_e = sqrt(sum((dmdy.*[y.Err]).^2) + sum((dmdx.*[x.Err]).^2));
%b_e = sqrt(sum((dbdy.*[y.Err]).^2) + sum((dbdx.*[x.Err]).^2));

% Uncertainty in yp
e_yp_vals = b_e;

% TOTAL UNCERTAINTY ======================================================
yp_e = sqrt(e_yp_stat^2 + e_yp_vals^2);

yp = UC(yp_v, yp_e,'projected');

%Here y = m*(x-xp) + b
m = UC(m_v, m_e, 'm');
bt = UC(b_v, b_e);

%Translate b back into the non-shifted coordinate system
% so y = m*x + b
bt = bt - m*xp;
b = UC([bt.Value],[bt.Err],'b');


