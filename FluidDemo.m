% Demo script for Fluid class
%
%------------------------------------------------------------------------------
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
%
%------------------------------------------------------------------------------

clear all
close all
clc

% Load fluid data from NIST (you only have to do this once per fluid, then the
% data is saved in the @Fluid folder)
Fluid.GetNISTData();

% Use a GUI for your scripts to select the fluid type if it changes often
fluid_name = Fluid.SelectFluidGUI();

% or just declare the fluid name manually to avoid the GUI
% fluid_name = 'H2';

% Create a Fluid
f = Fluid(fluid_name);

% Get the density of that fluid
density1 = f.Density({10,'bar'},{280,'K'},'g_L');

% Or using default units (bar, K, kg/m3 or g/L)
density2 = f.Density(10,280);

% Or using arrays for P and T to get a density array
P = 10:1:20;
T = 300*ones(size(P));
density3 = f.Density(P,T);

% If you want the partial derivative of density with respect to P and T
% to use for uncertainty calculations
[rho, drho_dP, drho_dT] = f.Density(10,280);


