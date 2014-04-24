function [hData, hBarX, hBarY] = plot(x,y,varargin)
    % Plot function, calls errorbars_xy
    
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
    
    if ~isa(x,'UC')
        x = UC(x,0,'x');
    end
    if ~isa(y,'UC')
        y = UC(y,0,'y');
    end
    
    %[hData, hEx, hEy] = errorbars_xy(gca,[x.Value],[y.Value],...
    %                             [x.Err],[y.Err],-1,-1);

    xVal = [x.Value];
    e_x = [x.Err];
    yVal = [y.Value];
    e_y = [y.Err];
    
    %Set negative spans to 1% of the relevant width
    x_scale = get(gca,'XLim');
    y_scale = get(gca,'YLim');
    
    x_scale_span = (max(x_scale) - min(x_scale)).*0.01;
    y_scale_span = (max(y_scale) - min(y_scale)).*0.01;
    
    x_data_span = (max(xVal) - min(xVal)) * 0.01;
    y_data_span = (max(yVal) - min(yVal)) * 0.01;
    
    span_x = max([y_scale_span y_data_span]);
    span_y = max([x_scale_span x_data_span]);
    

    %Parse parameter inputs
    Inputs = get_user_flags(varargin);

    %Hold the figure axes during plotting
    init_hold = ishold(gca);
    hold(gca,'on');

    %Plot X error bars
    if max(abs(e_x)) > 0
        [barx, bary] = get_bar_vectors(yVal, xVal-e_x, xVal+e_x, span_x);
        hBarX = plot(gca, barx, bary,...
                     'Color',Inputs.ErrorBarColor,...
                     'LineWidth',Inputs.ErrorBarLineWidth);
    else
        hBarX = 0;
    end

    %Plot Y error bars
    if max(abs(e_y)) > 0
        [bary, barx] = get_bar_vectors(xVal, yVal-e_y, yVal+e_y, span_y);
        hBarY = plot(gca, barx, bary,...
                     'Color',Inputs.ErrorBarColor,...
                     'LineWidth',Inputs.ErrorBarLineWidth);
    else
        hBarY = 0;
    end

    %Plot data points
    hData = plot(gca, xVal, yVal,...
                 'Line','none',...
                 'Marker',Inputs.Marker,...
                 'MarkerFaceColor',Inputs.MarkerFaceColor,...
                 'MarkerSize',Inputs.MarkerSize,...
                 'Color',Inputs.MarkerEdgeColor,...
                 'LineWidth',Inputs.MarkerLineWidth);

    %Set the hold state back to what it was when plot was called
    if ~init_hold
        hold(gca,'off');
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
