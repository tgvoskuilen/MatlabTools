classdef Fluid
    % Class for fluid properties based on NIST data.

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


    % This class relies on NIST data saved in the @Fluid folder. Currently 
    % supported fluids are:
    %   Hydrogen (H2)
    %   Nitrogen (N2)
    %   Helium   (He)
    %   Methane  (CH4)
    %
    % More fluids can be added by modifying GetNISTData below


    %-------------------------------------------------------------------------
    % Usage Instructions:
    %-------------------------------------------------------------------------
    % 1. Make sure the @Fluid folder is on your MATLAB path
    %
    % 2. Create a fluid object in your code using its name:
    %     H2 = Fluid('H2');
    %
    % 3. Access fluid properties using the Fluid class methods:
    %
    %     rho = H2.Density({10,'bar'},{280,'K'},'g_L');
    %
    %    or more simply (using the default units of bar, K, and g/L):
    %
    %     rho = H2.Density(10,280);
    %
    %    Other properties are accessed similarly:
    %      f = H2.Fugacity({10,'bar'},{280,'K'},'bar');
    %      Z = H2.Compressibility({10,'bar'},{280,'K'});
    %
    % 4. For uncertainty analysis, the density method also returns the
    %    derivative of density with respect to pressure and temperature
    %
    %     [rho, drho_dP, drho_dT] = H2.Density(10, 280);
    %

    %Fluid properties
    properties (SetAccess = private)
        P
        T
        rho
        Z
        f
    end
    
    %Units
    properties (SetAccess = private)
        pUnits = struct('bar',[1 0],'psi',[14.5037738 0],'atm',[1.01325 0]);
        tUnits = struct('K',[1 0],'C',[1 273.15]);
        rhoUnits = struct('g_ml',1,'kg_L',1,'kg_m3',0.001,'g_L',0.001);
    end
    
    %Static methods
    methods(Static)
        % Get fluid data from NIST database. Modify to add new fluids
        function GetNISTData()

            % Get User Inputs
            prompt = {'Enter Gas Type (H2, He, etc...):',...
                      'Enter T_{min} (K)',...
                      'Enter T_{max} (K)',...
                      'Enter T_{increment}(K)',...
                      'Enter P_{min} (bar)',...
                      'Enter P_{max} (bar)'};
            title = 'NIST Property Lookup Inputs';
            defaults = {'H2','50','400','5','1','700'};
            options.Interpreter='tex';

            UserInputs = inputdlg(prompt,title,1,defaults,options);

            %Quit on "Cancel"
            if isempty(UserInputs)
               return; 
            end
            pause(0.1);

            %Convert string inputs to numeric values
            Tmin  = str2double(UserInputs{2});
            Tmax  = str2double(UserInputs{3});
            Tinc  = str2double(UserInputs{4});
            Plow  = str2double(UserInputs{5});
            Phigh = str2double(UserInputs{6});

            %==================================================================
            % Match Gas Type
            %==================================================================
            % Constants - Gas selection data - add new gas data here to lookup
            %             other gasses than those listed
            %  To find its NIST code, go to 
            %  http://webbook.nist.gov/chemistry/fluid/ and select the fluid.
            %  Navigate through to the properties and click on the
            %  link to get a tab-delimited text file. Look for the 
            %  '...ID=C#####' in the URL and copy the C#### code to here.
            %

            Gas(1).Name = 'H2';
            Gas(1).MW = 2*1.00794; %g/mol
            Gas(1).NISTCode = 'C1333740';

            Gas(2).Name = 'He';
            Gas(2).MW = 4.002602; %g/mol
            Gas(2).NISTCode = 'C7440597';

            Gas(3).Name = 'N2';
            Gas(3).MW = 2*14.0067; %g/mol
            Gas(3).NISTCode = 'C7727379';

            Gas(4).Name = 'CH4';
            Gas(4).MW = 4*1.00794+12.0107; %g/mol
            Gas(4).NISTCode = 'C74828';

            Gas(5).Name = 'C3H8';
            Gas(5).MW = 8*1.00794+3*12.0107; %g/mol
            Gas(5).NISTCode = 'C74986';
            
            %Match the gas structure with the input gas type
            match = strcmpi(UserInputs{1},{Gas.Name});
            if any(match)
                GasID = find(match,1);
            else
                error('Invalid gas string: "%s"',UserInputs{1});
            end

            %NIST Database URL Constants
            baseurl1 = 'http://webbook.nist.gov/cgi/fluid.cgi?Action=Data&Wide=on&ID=';
            baseurl2 = '&Type=IsoTherm&PLow=';
            baseurl3 = '&PHigh=';
            baseurl4 = '&PInc=1&T=';
            baseurl5 = '&RefState=DEF&TUnit=K&PUnit=bar&DUnit=kg%2Fm3&HUnit=';
            baseurl6 = 'kJ%2Fkg&WUnit=m%2Fs&VisUnit=uPa*s&STUnit=N%2Fm';

            %==================================================================
            % Download NIST Data
            %==================================================================
            
            %Make a clean folder to store text files
            if isdir(Gas(GasID).Name)
                rmdir(Gas(GasID).Name,'s')
            end
            mkdir(Gas(GasID).Name);

            %Download text data files from NIST
            T = Tmin:Tinc:Tmax;
            LT = length(T);
            Pl = sprintf('%i',Plow);      %make Plow into a string
            Ph = sprintf('%i',Phigh);     %make Phigh into a string
            hWait = waitbar(0, 'Downloading NIST Data...');
            for t = 1:LT
                Tstr = sprintf('%i',T(t));     %make T into a string
                waitbar((T(t)-Tmin)/(Tmax-Tmin),hWait);
                url = java.net.URL(strcat(baseurl1,Gas(GasID).NISTCode,...
                    baseurl2,Pl,baseurl3,Ph,baseurl4,Tstr,baseurl5,baseurl6));
                is = openStream(url);          
                isr = java.io.InputStreamReader(is);
                br = java.io.BufferedReader(isr);           
                fid = fopen(strcat(Gas(GasID).Name,'/',Tstr,...
                    'K_',Pl,'-',Ph,'bar.txt'),'w');
                for i=1:204
                    s = readLine(br);             %read the first line
                    line = char(s);               %change it to a MATLAB string
                    fprintf(fid,'%s\n',line);     %write to file
                end
                fclose(fid);                      %close the file
            end
            close(hWait);
            pause(0.1);


            %==================================================================
            % Create parameter arrays
            %==================================================================
            
            %Calculate parameters
            hWait = waitbar(0, 'Processing Data...');
            n = min([203 round(Phigh-Plow)+1]);
            Ru = 8.314472; %J/mol-K OR m^3-Pa/mol-K
            Rsi = Ru/Gas(GasID).MW; %kJ/kg-K
            Re = Rsi * 10; %cm^3-bar/g-K

            %Preallocate matrices for raw data
            
            % get better n, number of pressures
            
            rho_full = zeros(n,LT);
            U_full = zeros(n,LT);
            H_full = zeros(n,LT);
            S_full = zeros(n,LT);

            %Load raw data
            for t = 1:LT
                waitbar(0.75*t/LT,hWait);
                
                %Load raw data
                Tstr = sprintf('%i',T(t));
                filename = strcat(Gas(GasID).Name,'/',Tstr,'K_', ...
                                  Pl,'-',Ph,'bar.txt');
                fid = fopen(filename,'r');
                C = textscan(fid,'%s','Delimiter','\t');
                fclose(fid);
                
                if any(strcmpi(C{1},'liquid'))
                    error('Fluid:GetNISTData',...
                          'Fluid is liquid at specified conditions');
                end
                
                %Transfer data into variables
                rho_full(:,t)=str2double(C{1}(17:14:end))'./1000; %g/cm^3
                U_full(:,t)=str2double(C{1}(19:14:end))';   %kJ/kg
                H_full(:,t)=str2double(C{1}(20:14:end))';   %kJ/kg
                S_full(:,t)=str2double(C{1}(21:14:end))';   %kJ/kg-K
            end

            %Get P lookup vector and remove duplicate rows
            % NIST puts duplicate rows at phase change points
            P_raw(:,1) = str2double(C{1}(16:14:end,1))'; %bar
            [P, indices] = unique(P_raw);                %bar

            %Remove duplicated rows in full data matrices
            rho = rho_full(indices,:);
            U = U_full(indices,:);
            H = H_full(indices,:);
            S = S_full(indices,:);

            waitbar(0.8,hWait);

            %Calculate other parameters (G, f, Z)
            Tmat = repmat(T,length(P),1);
            Pmat = repmat(P,1,length(T));
            G = H - Tmat.*S;
            G0 = repmat(G(1,:),length(P),1);
            f = exp((G - G0)./(Rsi .* Tmat));
            Z = Pmat./(rho.*Tmat.*Re);

            waitbar(0.85,hWait);

            %==================================================================
            % Save the property data to a .mat file
            %==================================================================

            %The units of the property file are:
            %  P (bar), T (K), fugacity (bar), 
            %  compressibility (-), density (g/ml)
            filename = strcat('NIST_',Gas(GasID).Name,'_Props.mat');
            save(filename,'T','P','f','Z','rho')
            
            fluidPath = fileparts(which('Fluid'));
            movefile(filename,strcat(fluidPath,filesep,filename));
            
            rmdir(Gas(GasID).Name,'s')
            waitbar(1,hWait);
            close(hWait);

            fprintf('%s property data download complete.\n', ...
                    Gas(GasID).Name);
        end
    
        function fluid_list = GetAvailableFluids()
            
            fluidPath = fileparts(which('Fluid'));
            propfiles = dir(strcat(fluidPath,filesep,'*_Props.mat'));
            fluid_list = cell(1,length(propfiles));
            for i = 1:length(propfiles)
                C = textscan(propfiles(i).name,'%s','delimiter','_');
                fluid_list{i} = C{1}{2};
            end
        end 
        
        function fluid = SelectFluidGUI()

            fluid_list = Fluid.GetAvailableFluids();
            
            %Prompt to select data folder from the valid options
            [fls,v] = listdlg('Name','Select a Fluid',...
                                  'ListSize',[200 200],  ...
                                  'PromptString','Select a Fluid to Use:', ...
                                  'SelectionMode','Single', ...
                                  'ListString',fluid_list);
            pause(0.1)

            %Exit on 'cancel' and return an empty cell
            if v == 0
                fluid = '';
            else
                fluid = fluid_list{fls};
            end
        end 
    end
    
    
    %--------------------------------------------------------------------------
    %Class methods
    methods
        
        %Create object from the NIST property data tables
        function g = Fluid(name)
            if nargin ~= 0
                try
                    fluidPath = fileparts(which('Fluid'));
                    matfile = fullfile(fluidPath,strcat('NIST_',name,'_Props.mat'));
                    if exist(matfile,'file')
                        fluid = load(matfile);
                    else
                        error('MATLAB:Fluid:Type','Unrecognized fluid type');
                    end
                    g.P = fluid.P;
                    g.T = fluid.T;
                    g.rho = fluid.rho;
                    g.Z = fluid.Z;
                    g.f = fluid.f;
                catch err
                    if strcmp(err.identifier,'MATLAB:Fluid:Type')
                        rethrow(err)
                    else
                        error('MATLAB:Fluid:FileError','Unable to load file');
                    end
                end
            end
        end
                
        function [rho, drho_dP, drho_dT] = Density(obj, P, T, rhoUnit)
            %P and T can be either scalars, vectors, or a cell with the
            %first entity a scaler or vector and the second entity a unit
            %string
            if nargin >= 3
                if iscell(P)
                    Pval = P{1}/obj.pUnits.(P{2})(1);
                else
                    Pval = P;
                end
                if iscell(T)
                    Tval = T{1}/obj.tUnits.(T{2})(1) + obj.tUnits.(T{2})(2);
                else
                    Tval = T;
                end
                if nargin == 4
                    rhoU = obj.rhoUnits.(rhoUnit);
                else
                    rhoU = 1;
                end
                
                dP = 1; %bar
                dT = 1; %K
                
                % Use the ideal gas law if P is less than min(obj.P)
                low_pressure = false;
                
                if min(min(Pval)) < min(obj.P)
                    low_pressure = true;
                    Porig = Pval;
                    Pval(Pval<min(obj.P)) = min(obj.P);
                end
                
                if max(max(Pval)) > max(obj.P)
                    Pval(Pval>max(obj.P)) = max(obj.P)-dP;
                    warning('MATLAB:Fluid:PropertyWarning',...
                            'Input pressure is higher than allowed');
                end
                
                if max(max(Tval)) > max(obj.T) || min(min(Tval)) < min(obj.T)
                    Tval(Tval>max(obj.T)) = max(obj.T)-dT;
                    Tval(Tval<min(obj.T)) = min(obj.T);
                    warning('MATLAB:Fluid:PropertyWarning',...
                            'Input temperature is out of range');
                end
                
                rho = interp2(obj.T, obj.P, obj.rho, Tval, Pval, 'linear')/rhoU; %g/ml
                rho_Pp = interp2(obj.T, obj.P, obj.rho, Tval, Pval+dP, 'linear')/rhoU; %g/ml
                rho_Tp = interp2(obj.T, obj.P, obj.rho, Tval+dT, Pval, 'linear')/rhoU; %g/ml
                    
                if low_pressure
                    rho(Porig<min(obj.P)) = rho(Porig<min(obj.P)) .* Porig(Porig<min(obj.P));
                    rho_Pp(Porig<min(obj.P)) = rho_Pp(Porig<min(obj.P)) .* Porig(Porig<min(obj.P));
                    rho_Tp(Porig<min(obj.P)) = rho_Tp(Porig<min(obj.P)) .* Porig(Porig<min(obj.P));
                end
                
                drho_dP = (rho_Pp - rho)/dP;
                drho_dT = (rho_Tp - rho)/dT;
            else
                error('MATLAB:Fluid:PropertyError',...
                    'You must enter a pressure and temperature to get density');
            end
        end

        function f = Fugacity(obj, P, T, fUnit)
            if nargin >= 3
                if iscell(P)
                    Pval = P{1}/obj.pUnits.(P{2})(1);
                else
                    Pval = P;
                end
                if iscell(T)
                    Tval = T{1}/obj.tUnits.(T{2})(1) + obj.tUnits.(T{2})(2);
                else
                    Tval = T;
                end
                if nargin == 4
                    fU = obj.pUnits.(fUnit);
                else
                    fU = 1;
                end
                if max(max(Pval)) > max(obj.P) || min(min(Pval)) < min(obj.P)
                    error('MATLAB:Fluid:OutOfRange',...
                        'Pressure out of range (%1.0f to %1.0f bar)',...
                        min(obj.P),max(obj.P));
                end
                if max(max(Tval)) > max(obj.T) || min(min(Tval)) < min(obj.T)
                    error('MATLAB:Fluid:OutOfRange',...
                        'Temperature out of range (%2.0f to %2.0f K)',...
                        min(obj.T),max(obj.T));
                end
                f = interp2(obj.T, obj.P, obj.f, Tval, Pval, 'linear')./fU(1)+fU(2); %bar
            else
                error('MATLAB:Fluid:PropertyError',...
                    'You must enter a pressure and temperature to get fugacity');
            end
        end

        function z = Compressibility(obj, P, T)
            if nargin == 3
                if iscell(P)
                    Pval = P{1}/obj.pUnits.(P{2})(1);
                else
                    Pval = P;
                end
                if iscell(T)
                    Tval = T{1}/obj.tUnits.(T{2})(1) + obj.tUnits.(T{2})(2);
                else
                    Tval = T;
                end
                if max(max(Pval)) > max(obj.P) || min(min(Pval)) < min(obj.P)
                    error('MATLAB:Fluid:OutOfRange',...
                        'Pressure out of range (%1.0f to %1.0f bar)',...
                        min(obj.P),max(obj.P));
                end
                if max(max(Tval)) > max(obj.T) || min(min(Tval)) < min(obj.T)
                    error('MATLAB:Fluid:OutOfRange',...
                        'Temperature out of range (%2.0f to %2.0f K)',...
                        min(obj.T),max(obj.T));
                end
                z = interp2(obj.T, obj.P, obj.Z, Tval, Pval, 'spline'); %-
            else
                error('MATLAB:Fluid:PropertyError',...
                'You must enter a pressure and temperature to get compressibility');
            end
        end
    end
    
end
