% Figure creation demo/template for MATLAB
%
%--------------------------------------------------------------------------
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
%--------------------------------------------------------------------------
%
% This script generates some pseudo-data, then makes two journal-quality
% plots of the generated data. It can be used as a template or guide for
% making plots using Matlab.

%Keep MLint quiet
%#ok<*UNRCH>

clear all
close all
clc

%% ========================================================================
% Plot parameters
%==========================================================================

%Boolean switches:
% It is often useful to set flags for thing you anticipate changing
% often. For example, you could use a "plot_in_color" flag, or a
% "fig_type = 'presentation' or 'journal'" to make different types of figures.
% Setting "save_figures" to false makes it run much faster, so use this
% until you are happy with how the figures look, then switch it to true.
save_figure = false;
plot_in_color = false;

%Define relevant figure parameters here. If you have several figures, this
% guarantees consistency between them and makes it easy to modify them all
% at once.
% Typical criteria for journal figures are:
%  - Width of 3.25 to 3.5 inches (for 2 column journals)
%  - Font size of 7 pts or larger (some journals allow 4.5 or larger)
%  - Sans Serif font face (Arial, Helvetica, etc...)
%  - Minimum line weight of 1 pt
%  - Reproducibility in black and white is generally recommended. Even if
%     the journal is in color, people print in black and white still.
FontSize = 9;
LegendFontSize = 9;
FontName = 'Helvetica';
FigWidth = 3.5;      %inches
FigHeight = 3;       %inches
DataLineWidth = 1;   %points
TheoryLineWidth = 2; %points
AxisLineWidth = 1;   %points
DataMarkerSize = 5;  %points

%Make two sets of colors for color or B&W plots. Color vectors are [R G B]
% components, with values from 0 to 1
if plot_in_color
    colors = {[1 0 0],[0 0 1]}; %Red and blue
else
    colors = {[1 1 1],[0.5 0.5 0.5]}; %White and grey
end


%% ========================================================================
% Make up some pseudo-data to plot
%==========================================================================

%First, generate some pseudo-data. We'll use structures to demonstrate how
% to make formatting automatically associated with the data. If you put
% your data into structures like this, you can make markers and other 
% features consistent and easily modified throughout your figures.
%
% - Use LaTeX commands for greek letters, special symbols,
%    italics and boldface: {\it[text]} to set italics, {\bf[text]} for
%    boldface, and many more 'fancy' looks

%Measurements
meas.width = (1:0.5:5)';
meas.accel = exp(meas.width) + 8.*rand(size(meas.width)) + 10;
meas.e_accel = 8 .* ones(size(meas.width));
meas.name = 'Measurement (\mu \pm \sigma)';
meas.marker = 'o';
meas.color = colors{1};

%Theory
theory.width = (0:0.005:5)';
theory.accel = exp(theory.width) + 10;
theory.name = 'Theory';

%Literature values
jenkins.width = [2.2; 4.1];
jenkins.accel = [17; 75];
jenkins.name = 'Jenkins {\itet al.} [3]';
jenkins.marker = 's';
jenkins.color = colors{2};


%% ========================================================================
% Now for the actual plot creation
%==========================================================================

%Create the figure and set its size in inches
% - If you make this setting the same size as your final figure size,
%    you won't have to worry about rescaling things and final font sizes,
%    it will appear as it does on screen
hFig1 = figure('Units','Inches','Position',[2 2 FigWidth FigHeight]);
set(hFig1,'Name','Normal Scale'); %Helpful to set a name if you have a lot of plots
hold on
    
%Plot the data and get handles for each plotted item
% - If you need error bars, you can use the 'errorbar' function.
% - If not, you can just use 'plot'
hTheory  = plot(theory.width, theory.accel);
hJenkins = plot(jenkins.width, jenkins.accel);
hMeas    = errorbar(meas.width, meas.accel, meas.e_accel);


%Set the display properties for each data series plotted on the graph
% - Set 'DisplayName' to what you want to appear in the legend
% - Use formatting flags or data structure attributes to set the 
%    other major properties

% Format the error bar hat size and color
hMeasChildren = get(hMeas,'Children');
errorbarHats = get(hMeasChildren(2),'XData');

errorbarHats(4:9:end) = errorbarHats(1:9:end) - 0.08;
errorbarHats(7:9:end) = errorbarHats(1:9:end) - 0.08;
errorbarHats(5:9:end) = errorbarHats(1:9:end) + 0.08;
errorbarHats(8:9:end) = errorbarHats(1:9:end) + 0.08;

set(hMeasChildren(2), 'XData', errorbarHats, 'Color', [0.3 0.3 0.3]);

set(hMeas,...
    'DisplayName',meas.name,... 
    'LineStyle','none',...          No line between points
    'LineWidth',DataLineWidth,...   Edge line width
    'Marker',meas.marker,...        Data marker style
    'MarkerSize',DataMarkerSize,... Data marker size
    'MarkerEdgeColor','k',...       Data marker edge color
    'MarkerFaceColor',meas.color); %Data marker face color

set(hJenkins,...
    'DisplayName',jenkins.name,...  
    'LineStyle','none',...            No line between points
    'LineWidth',DataLineWidth,...     Line width
    'Marker',jenkins.marker,...       Data marker style
    'MarkerSize',DataMarkerSize,...   Data marker size
    'MarkerEdgeColor','k',...         Data marker edge color
    'MarkerFaceColor',jenkins.color);%Data marker face color

set(hTheory,...
    'DisplayName',theory.name,...
    'LineStyle','-',...             Solid line
    'Color','k',...                 Black
    'LineWidth',TheoryLineWidth);  %Theory weight line

%Apply axis labels to the current axes
%Use LaTeX for greek letters, subscripts, and superscripts. Enclose
% subscripts and superscripts in {} if they are more than 1 character.
% For example: e^{-E/RT} or K_{r,j}
hXLabel = xlabel('Width (\mum)');  
hYLabel = ylabel('Acceleration (m^2/s)');
set([hXLabel hYLabel],'FontSize',FontSize,'FontName',FontName);

%Format the axes. The following items are essential:
% - Turn the bounding box on
% - Enable inward facing tick marks
% - Use minor tick marks in most cases
% - Set the tick mark size to 0.02, slightly larger than default
set(gca,...
    'FontSize',FontSize,...
    'FontName',FontName,...
    'LineWidth',AxisLineWidth,...
    'Box','on',...                Add a bounding box around the plot
    'TickDir','in',...            Use inward facing tick marks
    'TickLength',[0.02 0.02],...  Set tick mark size, percent of width
    'XMinorTick','on',...
    'YMinorTick','on',...
    'XLim',[0 6],...              Set limits (optional)
    'YLim',[0 200],...
    'XTick',[0 1 2 3 4 5 6],...   Manually set axes numbering (optional)
    'YTick',[0 20 40 60 80 100 120 140 160 180 200]);
   

%To make a multi-column legend:
% The default legends can only be created horizontally or vertically in
% MATLAB. To make a more complex legend, you will have to make several
% horizonal or vertical legends and position them next to each other.
% However, MATLAB only allows 1 legend per axes. The solution is to create
% an invisible axes for each new legend you want, as follows:
%
%  ax(1) = gca;  %save the current axes handle
%  ax(2) = axes('Position',get(ax(1),'Position'),'Visible','off');
%
%  hLegend1 = legend(ax(1),[hMeas, hJenkins]);
%  hLegend2 = legend(ax(2),hTheory);
%
% Then position and format your two legends so they look nice.
% To get the legend's current size and position ([x, y, w, h]) use
%  L1Pos = get(hLegend1,'Position')
%  L2Pos = get(hLegend2,'Position')
%
% To put legend 2 to the right of legend 1, you could do
%  set(hLegend2,'Position',[L1Pos(1)+L1Pos(3) L1Pos(2) L2Pos(3) L2Pos(4)])
%
% You may have to play around this this to get them positioned nicely


%Create the legend
% - The text is set automatically based on the DisplayName you set
%    earlier for each item
hLegend = legend([hMeas, hJenkins, hTheory],'Location','NorthWest');

%Format the legend. Whether to remove the box or not is a matter of
% preference and context.
set(hLegend,...
    'FontSize',LegendFontSize,...
    'FontName',FontName,...
    'Box','off',...    Remove the legend box if it looks better
    'Color','none');  %Set the fill color to none for a transparent box


if save_figure
    %Set the paper mode so it is rendered as positioned on screen
    set(hFig1, 'PaperPositionMode', 'auto');
    
    %Multiple acceptable save options using "print"
    print(hFig1,'-depsc2','MyPlot.eps');          %Save it as an EPS image
    print(hFig1,'-dtiff','-r1200','MyPlot.tif');  %Save it as a 1200 dpi TIFF image
    % WARNING:
    %  If you use the "Save" button that appears on the figure to save a TIFF,
    %  you will get a VERY low resolution image that looks poor in almost any
    %  medium. You must use script commands to get high resolution TIFF
    %  images.
    
    %pdfs require a little extra work to size the paper correctly
    set(hFig1, 'PaperSize', [FigWidth FigHeight]);
    print(hFig1,'-dpdf','MyPlot.pdf');            %Save it as a pdf
end




%% ========================================================================
% Now lets plot the same data on a log scale
%  Because we associated the plot parameters with the data being plotted
%  using structures, the second plot is consistent with the first plot.
%==========================================================================

%Create the figure and set its size in inches
hFig2 = figure('Units','Inches','Position',[6 2 FigWidth FigHeight]);
set(hFig2,'Name','Log Scale');

%Plot the data and get handles for each plotted item
% - The 'hold on' was moved here to lock in the 'semilogy' plot before
%    'holding' the plot attributes constant
hTheory  = semilogy(theory.width, theory.accel);
hold on
hJenkins = plot(jenkins.width, jenkins.accel);
hMeas = errorbar(meas.width, meas.accel, meas.e_accel);

%Set properties for each data series plotted on the graph
hMeasChildren = get(hMeas,'Children');
errorbarHats = get(hMeasChildren(2),'XData');

errorbarHats(4:9:end) = errorbarHats(1:9:end) - 0.08;
errorbarHats(7:9:end) = errorbarHats(1:9:end) - 0.08;
errorbarHats(5:9:end) = errorbarHats(1:9:end) + 0.08;
errorbarHats(8:9:end) = errorbarHats(1:9:end) + 0.08;

set(hMeasChildren(2), 'XData', errorbarHats, 'Color', [0.3 0.3 0.3]);

set(hMeas,...
    'DisplayName',meas.name,... 
    'LineStyle','none',...          No line between points
    'LineWidth',DataLineWidth,...   Edge line width
    'Marker',meas.marker,...        Data marker style
    'MarkerSize',DataMarkerSize,... Data marker size
    'MarkerEdgeColor','k',...       Data marker edge color
    'MarkerFaceColor',meas.color); %Data marker face color

set(hJenkins,...
    'DisplayName',jenkins.name,...  
    'LineStyle','none',...            No line between points
    'LineWidth',DataLineWidth,...     Line width
    'Marker',jenkins.marker,...       Data marker style
    'MarkerSize',DataMarkerSize,...   Data marker size
    'MarkerEdgeColor','k',...         Data marker edge color
    'MarkerFaceColor',jenkins.color);%Data marker face color

set(hTheory,...
    'DisplayName',theory.name,...
    'LineStyle','-',...             Solid line
    'Color','k',...                 Black
    'LineWidth',TheoryLineWidth);  %Theory weight line

%Apply axis labels to the current axes
hXLabel = xlabel('Width (\mum)');  
hYLabel = ylabel('Acceleration (m^2/s)');
set([hXLabel hYLabel],'FontSize',FontSize,'FontName',FontName);

%Format the axes.
set(gca,...
    'FontSize',FontSize,...
    'FontName',FontName,...
    'LineWidth',AxisLineWidth,...
    'Box','on',...                %Add a bounding box around the plot
    'TickDir','in',...            %Use inward facing tick marks
    'TickLength',[0.02 0.02],...  %Set tick mark size, percent of width
    'XMinorTick','on',...
    'YMinorTick','on',...
    'XLim',[0.8 6],...             Set limits (optional)
    'YLim',[7 300],...
    'XTick',[1 2 3 4 5 6],...      Set tick marks (optional)
    'YTick',[10 20 30 50 70 100 140 200 300]);
   
%Create the legend
hLegend = legend([hMeas, hJenkins, hTheory],'Location','NorthWest');

%Format the legend
set(hLegend,...
    'FontSize',LegendFontSize,...
    'FontName',FontName,...
    'Box','off',...    Remove the legend box if it looks better
    'Color','none');  %Set the fill color to none for a transparent box

if save_figure
    %Set the paper mode so it is rendered as positioned on screen
    set(hFig2, 'PaperPositionMode', 'auto');

    %Multiple acceptable save options using "print"
    print(hFig2,'-depsc2','MyPlot2.eps');          %Save it as an EPS image
    print(hFig2,'-dtiff','-r1200','MyPlot2.tif');  %Save it as a 1200 dpi TIFF image
    
    %pdfs require a little extra work to size the paper correctly
    set(hFig2, 'PaperSize', [FigWidth FigHeight]);
    print(hFig2,'-dpdf','MyPlot2.pdf');            %Save it as a pdf
end




%% ========================================================================
% Now we'll plot it again on a log scale, but with more of 
%  matlab's awful default settings for comparison
%==========================================================================

%Create the figure and set its size in inches
hFig3 = figure('Units','Inches','Position',[6 6 FigWidth FigHeight]);
set(hFig3,'Name','Log Scale Poor Quality');

%Plot the data and get handles for each plotted item
hTheory  = semilogy(theory.width, theory.accel);
hold on
hJenkins = plot(jenkins.width, jenkins.accel);
hMeas = errorbar(meas.width, meas.accel, meas.e_accel);

%Set properties for each data series plotted on the graph
set(hMeas,'DisplayName',meas.name);
set(hJenkins,'DisplayName',jenkins.name,'LineStyle','none','Marker','s');
set(hTheory,'DisplayName',theory.name);

%Apply axis labels to the current axes
hXLabel = xlabel('Width (\mum)');  
hYLabel = ylabel('Acceleration (m^2/s)');

%Format the axes.
set(gca,'box','off');

%Create the legend
hLegend = legend([hMeas, hJenkins, hTheory],'Location','NorthWest');

if save_figure
    %Set the paper mode so it is rendered as positioned on screen
    set(hFig3, 'PaperPositionMode', 'auto');

    %This is what you get if you use the "Save" button on the figure to
    %save it as a TIFF
    print(hFig3,'-dtiff','MyPlot3.tif');

end
