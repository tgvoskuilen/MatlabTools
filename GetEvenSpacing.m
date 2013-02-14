% Get a range of indices that give evenly spaced data points to downsample
%
%------------------------------------------------------------------------------
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
%
%------------------------------------------------------------------------------
%
% Required Inputs:
%   x  A vector of x data
%   y  A vector of y data
%   N  The number of points to subdivide the vector into for plotting
%
% Optional Inputs:
%   x_mode (optional) - Either 'Log' or 'Linear' (default) to scale the
%                       resulting x range for log plotting
%   y_mode (optional) - Either 'Log' or 'Linear' (default) to scale the
%                       resulting y range for log plotting
%   x_range (optional)- Length to scale 'x' over (defaults to min/max)
%   y_range (optional)- Length to scale 'y' over (defaults to min/max)
%
% For example, if 'time' and 'F' are dense vectors of the 
% same length, you can subdivide them into 50 points with:
%
%   r = GetEvenSpacing(time, F, 50);
%   plot(time,F,'-r');
%   hold on;
%   plot(time(r), F(r), 'ok');
%
% so their markers are visible over the existing data
%
%------------------------------------------------------------------------------
function range = GetEvenSpacing(x, y, N, x_mode, y_mode, x_range, y_range)

    % No "up-sampling" considered
    if N > length(x)
        range = ones(size(x));
        return
    end

    %Set x_mode and y_mode to 'Linear' if not specified
    if ~exist('x_mode','var')
        x_mode = 'Linear';
    end
    
    if ~exist('y_mode','var')
        y_mode = 'Linear';
    end
    
    %Set x and y plot ranges
    if ~exist('x_range','var')
        x_range = [min(x) max(x)];
    end
    
    if ~exist('y_range','var')
        y_range = [min(y) max(y)];
    end
    
    % Make xs0 and ys0 that vary over the same order of magnitude
    if strcmp(x_mode,'Log') || strcmp(x_mode,'log')
        xs0 = log((x - x_range(1)) ./ (x_range(2) - x_range(1)));
    else
        xs0 = (x - x_range(1)) ./ (x_range(2) - x_range(1));
    end
    
    if strcmp(y_mode,'Log') || strcmp(y_mode,'log')
        ys0 = log((y - y_range(1)) ./ (y_range(2) - y_range(1)));
    else
        ys0 = (y - y_range(1)) ./ (y_range(2) - y_range(1));
    end
    
    %Make a coarse spline of the line to find its real, non-noisy length
    spl = 1:floor(length(xs0)/50):length(xs0);
    xss0 = xs0(spl);
    yss0 = spline(xs0,ys0,xss0);
    
    ssz = size(xss0);
    if ssz(1) > 1
        xss1 = [xss0(1); xss0(1:end-1)];
        yss1 = [yss0(1); yss0(1:end-1)];
    else
        xss1 = [xss0(1) xss0(1:end-1)];
        yss1 = [yss0(1) yss0(1:end-1)];
    end
    
    dss = sqrt((xss0-xss1).^2 + (yss0-yss1).^2);
    ss = cumsum(dss);
    
    yexit = find(xss0>1,1,'first');
    xexit = find(yss0>1,1,'first');
    if isempty(yexit)
        yexit = length(yss0);
    end
    if isempty(xexit)
        xexit = length(xss0);
    end
    
    exit_pt = min([yexit xexit]);
    span = max(ss(1:exit_pt)) / N;
    
    %Subdivide path into N segments and get transition points
    pivots = zeros(size(xs0));
    pivots(1) = 1;
    lastpt = 1;
    for i=2:length(xs0)
        del = sqrt((xs0(i)-xs0(lastpt)).^2 + (ys0(i)-ys0(lastpt)).^2);
        if del > span
            pivots(i) = 1;
            lastpt = i;
        end
    end
     
    range = find(pivots==1);
    
    
