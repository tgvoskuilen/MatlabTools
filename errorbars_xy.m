function [hData, hBarX, hBarY] = errorbars_xy(ax,x,y,e_x,e_y,span_x,span_y,varargin)
% This function plots X and/or Y error bars on a set of data.
%  
%  Required Inputs:
%    ax - Axes handle to plot on
%    x - A vector of x data points
%    y - A vector of y data points
%    e_x - A vector or scalar value of uncertainty in the x data points
%       (set to [] or 0 for no X-error bars, if an entry of e_x is zero
%        that bar will not be plotted. You can use this to plot only the
%        last error bar by entering [0 0 ... 0 e]. The same applies to e_y)
%    e_y - A vector or scalar value of uncertainty in the y data points
%       (set to [] or 0 for no Y-error bars)
%    span_x - A scalar or vector of the height (vertical) of the hats on the X error bars
%       (required, but ignored if e_x = [] or 0. If you enter -1 here the span is
%        calculated as 1% of the span of the y input data points)
%    span_y - A scalar or vector of the width (horizontal) of the hats on the Y error bars
%       (required, but ignored if e_y = [] or 0. If you enter -1 here the span is
%        calculated as 1% of the span of the x input data points)
%
%  Optional Inputs - Enter as a list of ('ParamName',value) pairs
%   'ErrorBarColor' - String or vector color
%   'ErrorBarLineWidth' - Numeric value
%   'Marker' - Marker string for data
%   'MarkerFaceColor' - Color string or vector
%   'MarkerEdgeColor' - Color string or vector
%   'MarkerSize' - Numeric value
%   'MarkerLineWidth' - Numeric value
%
%   Output:
%    Returns a vector of handles to the data, X error bars, and Y error
%    bars, respectively
%
% Example usage:
%   x = 0:1:10;
%   y = x.^2;
%   hFig = figure;
%   [hData, hErrX, hErrY] = errorbars_xy(gca, x, y, 0.5, 5, -1, -1);


%==========================================================================
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
%==========================================================================

    %Check that there are enough inputs
    if nargin < 7
        error('Error: Not enough input arguments');
    end

    %Check that the vectors are properly sized
    if ~isequal(size(x),size(y))
        error('Error: x and y must be the same size');
    end

    if ~isequal(size(x),size(e_x)) && length(e_x) ~= 1 && ~isempty(e_x)
        error('Error: e_x must be either a single value or a vector the same size as x');
    end

    if ~isequal(size(y),size(e_y)) && length(e_y) ~= 1 && ~isempty(e_y)
        error('Error: e_y must be either a single value or a vector the same size as y');
    end

    %Set negative spans to 1% of the relevant width
    x_scale = get(gca,'XLim');
    y_scale = get(gca,'YLim');
    
    x_scale_span = (max(x_scale) - min(x_scale)).*0.01;
    y_scale_span = (max(y_scale) - min(y_scale)).*0.01;
    
    x_data_span = (max(x) - min(x)) * 0.01;
    y_data_span = (max(y) - min(y)) * 0.01;
    
    span_x(span_x < 0) = max([y_scale_span y_data_span]);
    span_y(span_y < 0) = max([x_scale_span x_data_span]);
    

    %Parse parameter inputs
    Inputs = get_user_flags(varargin);

    %Hold the figure axes during plotting
    init_hold = ishold(ax);
    hold(ax,'on');

    %Plot X error bars
    if ~isempty(e_x)
        [barx, bary] = get_bar_vectors(y, x-e_x, x+e_x, span_x);
        hBarX = plot(ax, barx, bary,...
                     'Color',Inputs.ErrorBarColor,...
                     'LineWidth',Inputs.ErrorBarLineWidth);
    else
        hBarX = 0;
    end

    %Plot Y error bars
    if ~isempty(e_y)
        [bary, barx] = get_bar_vectors(x, y-e_y, y+e_y, span_y);
        hBarY = plot(ax, barx, bary,...
                     'Color',Inputs.ErrorBarColor,...
                     'LineWidth',Inputs.ErrorBarLineWidth);
    else
        hBarY = 0;
    end

    %Plot data points
    hData = plot(ax, x, y,...
                 'Line','none',...
                 'Marker',Inputs.Marker,...
                 'MarkerFaceColor',Inputs.MarkerFaceColor,...
                 'MarkerSize',Inputs.MarkerSize,...
                 'Color',Inputs.MarkerEdgeColor,...
                 'LineWidth',Inputs.MarkerLineWidth);

    %Set the hold state back to what it was when errorbars_xy was called
    if ~init_hold
        hold(ax,'off');
    end

end


%Build error bar vector
% v = vector of values
% l = low end
% h = high end
% span = vector of hat widths
function [para, perp] = get_bar_vectors(v, l, h, span)

    [npt,n] = size(l);
    
    %set high and low span
    vh = v+span;
    vl = v-span;
    
    %Set span to zero where l == h (error bar of zero)
    vh(l == h) = v(l == h);
    vl(l == h) = v(l == h);

    % build up NaN-separated vector for bars
    para = zeros(npt*9,n);
    para(1:9:end,:) = h;
    para(2:9:end,:) = l;
    para(3:9:end,:) = NaN;
    para(4:9:end,:) = h;
    para(5:9:end,:) = h;
    para(6:9:end,:) = NaN;
    para(7:9:end,:) = l;
    para(8:9:end,:) = l;
    para(9:9:end,:) = NaN;

    perp = zeros(npt*9,n);
    perp(1:9:end,:) = v;
    perp(2:9:end,:) = v;
    perp(3:9:end,:) = NaN;
    perp(4:9:end,:) = vh;
    perp(5:9:end,:) = vl;
    perp(6:9:end,:) = NaN;
    perp(7:9:end,:) = vh;
    perp(8:9:end,:) = vl;
    perp(9:9:end,:) = NaN;
    
end

%Parse input options.
% Following the spans, the following options are allowed:
%   'ErrorBarColor'
%   'ErrorBarLineWidth'
%   'Marker'
%   'MarkerFaceColor'
%   'MarkerEdgeColor'
%   'MarkerSize'
%   'MarkerLineWidth'
function Inputs = get_user_flags(args)

    % Define structure of inputs with default values
    Inputs = struct('ErrorBarColor','k',...
                    'ErrorBarLineWidth',0.8,...
                    'Marker','o',...
                    'MarkerFaceColor',[1 1 1],...
                    'MarkerEdgeColor','k',...
                    'MarkerSize',5,...
                    'MarkerLineWidth',0.8);

    % Verify that there are an even number of args
    nargs = size(args,2)/2;
    if floor(nargs) ~= nargs
        error('Error: Invalid parameter input combination');
    end
    
    % Put input arguments into structure
    %  This returns an error if you give an unexpected input.
    for i = 1:nargs
        flag = args{2*(i-1)+1};
        value = args{2*(i-1)+2};
        
        if isfield(Inputs,flag)
            Inputs.(flag) = value;
        else
            error('Error: Invalid flag string: %s',flag);
        end
    end

end
