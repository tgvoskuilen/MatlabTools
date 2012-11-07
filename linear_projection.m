function [ext, m, b] = linear_projection(x,y,e_x,e_y,xo)
% This function takes an x vector and y vector, and their associated 
% uncertainty vectors, and calculates the uncertainty at a given 
% extrapolated or interpolated point using a linear fit.
% All input vectors must be the same length.
%
% Inputs:
%     x  Vector of x values
%     y  Vector of y values
%   e_x  Vector of uncertainty of x values
%   e_y  Vector of uncertainty of y values
%    xo  Extrapolation point
%
% Outputs:
%   ext   Structure containing .value and .err for the
%          projected point
%     m   Structure containing .value and .err for 
%          the linear fit slope
%     b   Structure containing .value and .err for
%          the linear fit intercept
%

%==============================================================================
% Copyright (c) 2012, Tyler Voskuilen
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
%==============================================================================


% Check that all inputs are present =======================================
if nargin ~= 5
    error('Incorrect number of inputs');
end

% Check that the vectors are the same length ==============================
n = length(x);
if length(y) ~= n || length(e_x) ~= n || length(e_y) ~= n
    error('All input vectors must be the same length');
end

% PERFORM LINEAR FIT ======================================================
[P, S] = polyfit(x, y, 1);

% FIND STATISTICAL ERROR IN PROJECTED VALUE ===============================
[ext.value, e_yo_stat] = polyval(P,xo,S);

% FIND UNCERTAINTY IN yo DUE TO UNCERTAINTY IN X AND Y ====================
Sx = sum(x);
Sy = sum(y);
Sxy = sum(x.*y);
Sxx = sum(x.^2);

%y = mx+b
m.value = P(1);
b.value = P(2);

% b = (Sy*Sxx - Sx*Sxy)/(n*Sxx-Sx^2) = g/h
dbdy = (Sxx - x.*Sx) ./ (n*Sxx - Sx^2);

h = n.*Sxx - Sx.^2;
g = Sy.*Sxx - Sx.*Sxy;
hp = 2*n.*x - 2.*Sx;          %dh/dx
gp = 2.*Sy.*x - Sxy - y.*Sx;  %dg/dx
dbdx = (h.*gp - hp.*g)./h.^2;
    
% m = (n*Sxy - Sx*Sy)/(n*Sxx-Sx^2) = f/h
dmdy = (n*x - Sx)/(n*Sxx-Sx^2);

f = n.*Sxy - Sx.*Sy;
fp = n.*y - Sy; %df/dx
dmdx = (h.*fp - hp.*f)./h.^2;

% Uncertainty in m and b
m.err = sqrt(sum((dmdy.*e_y).^2) + sum((dmdx.*e_x).^2));
b.err = sqrt(sum((dbdy.*e_y).^2) + sum((dbdx.*e_x).^2));

% Uncertainty in yo
e_yo_vals = sqrt((xo*m.err)^2 + b.err^2);

% TOTAL UNCERTAINTY =======================================================
ext.err = sqrt(e_yo_stat^2 + e_yo_vals^2);
ext.err_stat = e_yo_stat;
ext.err_proj = e_yo_vals;
