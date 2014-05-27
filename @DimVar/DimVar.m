classdef DimVar
    % DimVar is a class is for handling dimensioned quantities in Matlab
    %
    % It is designed to be a "stand-in" replacement for numeric data in
    % Matlab that carries units and checks them during normal operations.
    %
    % For example, you could use it to calculate conduction with mixed
    % units as:
    %
    %  k = DimVar(4,'BTU-in/hr-ft^2-F');
    %  L = DimVar(5,'mm');
    %  A = DimVar(10,'cm^2');
    %  DT = DimVar(500,'R') - DimVar(200,'K');
    % 
    %  Q = k*A/L*DT;
    %
    % where in this case the units are propogated through. It also checks
    % for unit validity in math operations, so the following would generate
    % an error:
    %
    %  x = k + L
    %
    % since the units of k and L are different.
    %
    % The rules for writing the unit string are:
    %  * Use a single solidus (/) as the separator between numerator and
    %    denominator.
    %  * Use hyphens (-) to separate individual unit components
    %  * Indicate powers either with or without a '^' (m^3 or m3)
    %  * Indicate inverse units as either 1/x or x^-1
    %  * Temperatures will be treated as absolute unless you add the
    %    optional 'Relative' argument, as in DT = DimVar(10,'C','Relative')
    %    otherwise the 10 C value will be converted to 283.15 K rather 
    %    than 10 K. You can also deal with it by using the subtraction, so
    %    DT = DimVar(10,'C') - DimVar(0,'C')
    %
    % The most up-to-date version of this class is on Github at:
    %  http://github.com/tgvoskuilen/MatlabTools
    
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


    %----------------------------------------------------------------------
    properties (SetAccess = protected)
        Value = 0;  % Value (scalar or array)
    end
    
    %----------------------------------------------------------------------
    properties (Access = private)
        Unit = [0 0 0 0 0];  % Unit array [kg m s K kmol]
    end
    
    %----------------------------------------------------------------------
    properties (Dependent = true, SetAccess = private)
        UnitStr  % String representation of unit
    end
        
    %----------------------------------------------------------------------
    properties (Constant, Access = private)
        % uTable - Structure of recognized units. To add new units, add
        %          them to this structure
        uTable = struct...
        (...
        ... Mass units (kg,g,mg,lbm,lb)
            'kg', {1,        [1 0 0 0 0]}, ...
            'g',  {1e-3,     [1 0 0 0 0]}, ...
            'mg', {1e-6,     [1 0 0 0 0]}, ...
            'lbm',{0.453592, [1 0 0 0 0]}, ... 
            'lb', {0.453592, [1 0 0 0 0]}, ... Assume lb intended as mass
        ...
        ... Length units (km,m,cm,mm,um,nm,ft,in)
            'km', {1e3,    [0 1 0 0 0]}, ...
            'm',  {1,      [0 1 0 0 0]}, ...
            'cm', {1e-2,   [0 1 0 0 0]}, ...
            'mm', {1e-3,   [0 1 0 0 0]}, ...
            'um', {1e-6,   [0 1 0 0 0]}, ...
            'nm', {1e-9,   [0 1 0 0 0]}, ...
            'ft', {0.3048, [0 1 0 0 0]}, ...
            'in', {0.0254, [0 1 0 0 0]}, ...
        ...
        ... Time units (ms,s,min,hr)
            'ms',  {1e-3,  [0 0 1 0 0]}, ...
            's',   {1,     [0 0 1 0 0]}, ...
            'min', {60,    [0 0 1 0 0]}, ...
            'hr',  {3600,  [0 0 1 0 0]}, ...
        ...
        ... Temperature units (K,C,R,F)
            'K',   {1,             [0 0 0 1 0]}, ...
            'R',   {5/9,           [0 0 0 1 0]}, ...
            'C',   {[1 273.15],    [0 0 0 1 0]}, ...
            'F',   {[5/9 255.372], [0 0 0 1 0]}, ...
        ...
        ... Molar quantity units (mol,kmol)
            'kmol',  {1,    [0 0 0 0 1]}, ...
            'mol',   {1e-3, [0 0 0 0 1]}, ...
        ...
        ... Volume units (L,ml,cc)
            'L',  {1e-3, [0 3 0 0 0]}, ...
            'ml', {1e-6, [0 3 0 0 0]}, ...
            'cc', {1e-6, [0 3 0 0 0]}, ...
        ...
        ... Volumetric flow rate units (gpm,cfm)
            'gpm',  {1/15852,  [0 3 -1 0 0]}, ...
            'cfm',  {1/2119,   [0 3 -1 0 0]}, ...
        ...
        ... Frequency units (Hz,kHz,MHz,GHz,rpm)
            'Hz',  {1,    [0 0 -1 0 0]},...
            'kHz', {1e3,  [0 0 -1 0 0]},...
            'MHz', {1e6,  [0 0 -1 0 0]},...
            'GHz', {1e9,  [0 0 -1 0 0]},...
            'rpm', {1/60, [0 0 -1 0 0]},...
        ...
        ... Energy units (J,eV,mJ,kJ,MJ,BTU,erg,cal,kWh)
            'J',   {1,          [1 2 -2 0 0]},...
            'eV',  {1.6022e-19, [1 2 -2 0 0]},...
            'mJ',  {1e-3,       [1 2 -2 0 0]},...
            'kJ',  {1e3,        [1 2 -2 0 0]},...
            'MJ',  {1e6,        [1 2 -2 0 0]},...
            'BTU', {1055.05585, [1 2 -2 0 0]},...
            'erg', {1e-7,       [1 2 -2 0 0]},...
            'cal', {4.184,      [1 2 -2 0 0]},...
            'kWh', {3.6e6,      [1 2 -2 0 0]},...
        ...
        ... Power units (W,MW,mW,kW,hp)
            'W',  {1,          [1 2 -3 0 0]},...
            'MW', {1e6,        [1 2 -3 0 0]},...
            'mW', {1e-3,       [1 2 -3 0 0]},...
            'kW', {1e3,        [1 2 -3 0 0]},...
            'hp', {745.699872, [1 2 -3 0 0]},...
        ...
        ... Force units (N,lbf,dyne)
            'N',   {1,          [1 1 -2 0 0]}, ...
            'lbf', {4.44822162, [1 1 -2 0 0]}, ...
            'dyne',{1e-5,       [1 1 -2 0 0]}, ...
        ...
        ... Pressure units (psi,bar,Pa,kPa,MPa,torr,mbar,atm)
            'Pa',   {1,          [1 -1 -2 0 0]}, ...
            'kPa',  {1e3,        [1 -1 -2 0 0]}, ...
            'MPa',  {1e6,        [1 -1 -2 0 0]}, ...
            'bar',  {1e5,        [1 -1 -2 0 0]}, ...
            'mbar', {1e2,        [1 -1 -2 0 0]}, ...
            'torr', {133.322368, [1 -1 -2 0 0]}, ...
            'psi',  {6894.75729, [1 -1 -2 0 0]}, ...
            'atm',  {101325,     [1 -1 -2 0 0]}, ...
        ...
        ... Dynamic viscosity units (P,cP,mP)
            'P',   {0.1,    [1 -1 -1 0 0]}, ...
            'cP',  {0.001,  [1 -1 -1 0 0]}, ...
            'mP',  {0.0001, [1 -1 -1 0 0]}  ...
        );
    end
    
    %----------------------------------------------------------------------
    % Public static functions
    methods(Static)
        function ValidUnits()
            % Print a list of all valid units
            disp(fieldnames(DimVar.uTable(1)))
        end
    end
    
    %----------------------------------------------------------------------
    % Private static functions
    methods(Static, Access = private)
        
        %------------------------------------------------------------------
        function y = EvalDimlessFcn(A,f)
            % Evaluate a function by handle requiring dimensionless inputs
            [Av,Au] = DimVar.EqualizeInputs(A);
            if ~DimVar.IsDimless(Au)
                error('DimVar:DimlessFcn',...
                      'Arguments to %s() must be dimensionless',...
                      func2str(f));
            end
            y = f(Av);
        end
        
        %------------------------------------------------------------------
        function [U,dims] = CombineUnits(Au,Bu,f,checkEqual,opStr)
            % Combine two unit cell arrays
            
            if ~exist('checkEqual','var')
                checkEqual = false;
            end

            if checkEqual
                DimVar.CheckUnits(Au,Bu,opStr);
            end
            
            sa = size(Au);
            sb = size(Bu);
            
            if numel(Au) == numel(Bu) && all(sa(:)==sb(:))
                U = cellfun(@(x,y) f(x,y), Au, Bu, 'UniformOutput',false);
            elseif numel(Au) == 1
                U = cellfun(@(x) f(Au{1},x), Bu, 'UniformOutput',false);
            elseif numel(Bu) == 1
                U = cellfun(@(x) f(x,Bu{1}), Au, 'UniformOutput',false);
            else
                error('DimVar:CombineUnits',...
                      'Unequal array size');
            end
            
            dims = ~DimVar.IsDimless(U);
        end
        
        %------------------------------------------------------------------
        function isDimless = IsDimless(Au)
            % Check if a unit cell array is dimensionless
            dimless = cellfun(@(x) max(abs(x)) == 0, Au);
            isDimless = all(dimless(:));
        end
        
        
        %------------------------------------------------------------------
        function [Av,Au,Bv,Bu] = EqualizeInputs(A,B)
            % Extract value and unit array and cell array from inputs
            if isa(A,'DimVar')
                Av = reshape([A.Value],size(A));
                Au = reshape({A.Unit},size(A));
            else
                Av = A;
                Au = cell(size(A));
                Au = cellfun(@(x) [0 0 0 0 0],Au,'UniformOutput',false);
            end
            
            if exist('B','var')
                if isa(B,'DimVar')
                    Bv = reshape([B.Value],size(B));
                    Bu = reshape({B.Unit},size(B));
                else
                    Bv = B;
                    Bu = cell(size(B));
                    Bu = cellfun(@(x) [0 0 0 0 0],Bu,'UniformOutput',false);
                end
            end
        end
        
        %------------------------------------------------------------------
        function CheckUnits(Au,Bu,opStr)
            % Check if two sets of units are equal
            
            sa = size(Au);
            sb = size(Bu);

            if numel(Au) == numel(Bu) && all(sa(:)==sb(:))
                ma = cellfun(@(x,y) all(x==y), Au, Bu);
            elseif numel(Au) == 1
                ma = cellfun(@(x) all(Au{1}==x), Bu);
            elseif numel(Bu) == 1
                ma = cellfun(@(x) all(x==Bu{1}), Au);
            else
                error('DimVar:CheckUnits',...
                      'Unequal array size');
            end

            if ~all(ma(:))
                error('DimVar:CheckUnits',...
                      'Unit mismatch in "%s" operator',opStr);
            end
        end
        
        %------------------------------------------------------------------
        function [unit,factor] = ReadUnitStr(str)
            % Read the input unit string to a unit array and conversion
            % factor
            
            % Remove any parentheses or brackets
            str(str=='(') = '';
            str(str==')') = '';
            str(str=='[') = '';
            str(str==']') = '';
            
            % Split string into numerator and denominator
            [num,den] = DimVar.SplitFraction(str);
            
            % Split numerator and denominator into components
            nums = DimVar.SplitParts(num);
            dens = DimVar.SplitParts(den);
            
            % Extract base units and powers from components
            for i = 1:length(nums)
                nums{i} = DimVar.ReadUnitPower(nums{i},1);
            end
            
            for i = 1:length(dens)
                dens{i} = DimVar.ReadUnitPower(dens{i},-1);
            end
            
            % Join num and den cells
            parts = cell(length(nums)+length(dens),1);
            j = 1;
            for i = 1:length(nums)
                parts{j} = nums{i};
                j = j + 1;
            end
            for i = 1:length(dens)
                parts{j} = dens{i};
                j = j + 1;
            end
            
            % Read individual unit entries
            unit = [0 0 0 0 0];
            factor = 1;
            nonLinear = true;
            
            for i = 1:length(parts)
                [u,f] = DimVar.ReadBaseUnit(parts{i}{1});
                
                u = u.*parts{i}{2};
                f = f.^parts{i}{2};
                
                if length(f) == 1
                    nonLinear = false;
                end
                
                unit = unit + u;
                factor = factor * f;
            end
            
            if ~nonLinear
                factor = factor(1);
            end
        end
                
        %------------------------------------------------------------------
        function np = ReadUnitPower(str,sgn)
            % Read a string like 'm^3' or 'm3' and get the unit and power
            
            pid = strfind(str,'^');
            
            if isempty(pid)
                str = regexprep(str,'([0-9]+)','^$1');
                pid = strfind(str,'^');
            end
            
            if isempty(pid)
                base = str;
                power = sgn;
            else
                base = str(1:pid-1);
                power = str2double(str(pid+1:end))*sgn;
                
                if isnan(power)
                    error('DimVar:ReadUnitPower',...
                          'Unable to read numeric power from "%s"',str);
                end
            end
            
            np = {base, power};
        end
        
        %------------------------------------------------------------------
        function parts = SplitParts(str)
            % Split unit string into base components by hyphens
            
            ids = strfind(str,'-');
            
            if isempty(ids)
                if isempty(str)
                    parts = {};
                else
                    parts = {str};
                end
            else
                % Check for negative powers and remove from hyphen list
                npid = strfind(str,'^-');
                if ~isempty(npid)
                    for i = 1:length(npid)
                        ids = ids(ids~=npid(i)+1);
                    end
                end
            
                parts = cell(size(ids));
            
                ids = [0 ids];
                
                for i = 1:length(ids)-1
                    parts{i} = str(ids(i)+1:ids(i+1)-1);
                end
                parts{length(ids)} = str(ids(end)+1:end);
            end
        end
        
        %------------------------------------------------------------------
        function [num,den] = SplitFraction(str)
            % Split unit string into numerator and denominator
            sid = strfind(str,'/');

            if isempty(sid)
                num = str;
                den = '';
            elseif length(sid) == 1
                num = str(1:sid-1);
                den = str(sid+1:end);
                
                % Catch if numerator is just '1'
                if ~isnan(str2double(num))
                    num = '';
                end
            else
                error('DimVar:SplitFraction',...
                      'Too many solidus lines in unit fraction');
            end
        end
        
        %------------------------------------------------------------------
        function [unit,factor] = ReadBaseUnit(str)
            % Look up the base unit array and factor from a unit string
            
            if isfield(DimVar.uTable, str)
                [factor,unit] = DimVar.uTable.(str);
            else
                % Return an error for unknown units
                error('DimVar:ReadBaseUnit',...
                      'Unrecognized unit "%s"',str);
            end
            
        end
    end
    
    %----------------------------------------------------------------------
    methods
        
        %------------------------------------------------------------------
        function dv = DimVar(val, unit, isrel)
            % Constructor for a dimensioned variable
            [~,fldr] = fileparts(pwd);
            if strcmpi(fldr,'@DimVar')
                error('MATLAB:DimVar',...
                      'Do not work inside the "@DimVar" folder');
            end
            
            if nargin >= 2
                % Check if input specifies a relative quantity
                if exist('isrel','var')
                    if strcmpi(isrel,'relative')
                        isRel = true;
                    else
                        error('MATLAB:DimVar',...
                              'Unknown argument "%s"',isrel);
                    end
                else
                    isRel = false;
                end

                if ischar(unit)
                    [u,f] = DimVar.ReadUnitStr(unit);
                    if length(f) == 2 && ~isRel
                        v = val.*f(1) + f(2);
                    else
                        v = val.*f(1);
                    end
                    
                    dv(numel(v)) = DimVar();
                    for i = 1:numel(v)
                        dv(i).Value = v(i);
                        dv(i).Unit = u;
                    end
                    dv = reshape(dv,size(val));
                else
                    if ~iscell(unit) && length(unit) ~= 5
                        error('DimVar:DimVar',...
                              'Invalid input unit array');
                    end
                    
                    dv(numel(val)) = DimVar();
                    for i = 1:numel(val)
                        dv(i).Value = val(i);
                        if iscell(unit)
                            dv(i).Unit = unit{i};
                        else
                            dv(i).Unit = unit;
                        end
                    end
                    dv = reshape(dv,size(val));
                end
            elseif nargin == 1
                % Assume dimensionless if only number given
                dv(numel(val)) = DimVar();
                for i = 1:numel(val)
                    dv(i).Value = val(i);
                    dv(i).Unit = [0 0 0 0 0];
                end
                dv = reshape(dv,size(val));
            end
 
        end
        
        %------------------------------------------------------------------
        % Unit converter
        %------------------------------------------------------------------
        function val = Convert(self, unitStr)
            % Convert obj to a value with different units
            
            % First make sure obj and unitStr are consistent
            [u,f] = DimVar.ReadUnitStr(unitStr);
            [Av,Au] = DimVar.EqualizeInputs(self);
            DimVar.CheckUnits(Au,{u},'conversion');
            if length(f) == 2
                val = (Av - f(2)) ./ f(1);
            else
                val = Av./f;
            end
            val = reshape(val,size(self));
        end
        
        function val = NoUnits(self)
            % Remove unit type and return just SI value
            
            % First make sure obj and unitStr are consistent
            [Av,~] = DimVar.EqualizeInputs(self);
            val = reshape(Av,size(self));
        end
        
        function val = double(self)
            % Define conversion to double
            val = self.NoUnits();
        end


        %------------------------------------------------------------------
        % Operator overloading
        %------------------------------------------------------------------
        function y = plus(A, B)
            % Addition operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            Yu = DimVar.CombineUnits(Au,Bu,@(x,y) x, true, 'plus');
            y = DimVar(Av+Bv, Yu);
        end
        
        %------------------------------------------------------------------
        function y = minus(A, B)
            % Subtraction operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            Yu = DimVar.CombineUnits(Au,Bu,@(x,y) x, true, 'minus');
            y = DimVar(Av-Bv, Yu);
        end
        
        %------------------------------------------------------------------
        function y = uminus(A)
            % Negation operator
            [Av,Au] = DimVar.EqualizeInputs(A);
            y = DimVar(-Av,Au);
        end
        
        %------------------------------------------------------------------
        function y = uplus(A)
            % Unary + operator
            y = A;
        end
        
        %------------------------------------------------------------------
        function y = times(A, B)
            % Multiplcation operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            [Yu,dims] = DimVar.CombineUnits(Au,Bu,@(x,y) x+y);
            if dims
                y = DimVar(Av.*Bv, Yu);
            else
                y = Av.*Bv;
            end
        end
        
        %------------------------------------------------------------------
        function y = rdivide(A, B)
            % Division operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            [Yu,dims] = DimVar.CombineUnits(Au,Bu,@(x,y) x-y);
            if dims
                y = DimVar(Av./Bv, Yu);
            else
                y = Av./Bv;
            end
        end
        
        %------------------------------------------------------------------
        function y = power(A, B)
            % Power operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            
            if ~DimVar.IsDimless(Bu)
                error('DimVar:power',...
                      'Exponent must be dimensionless');
            end
            
            Bvc = arrayfun(@(x) x, Bv, 'UniformOutput',false);
            Yu = DimVar.CombineUnits(Au,Bvc,@(x,y) x.*y);
            
            % May not need to check dims
            y = DimVar(Av.^Bv, Yu);
        end
       
        %------------------------------------------------------------------
        function bool = lt(A, B)
            % Less than operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            DimVar.CheckUnits(Au,Bu,'less than');
            bool = (Av < Bv);
        end
        
        %------------------------------------------------------------------
        function bool = gt(A, B)
            % Greater than operator
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            DimVar.CheckUnits(Au,Bu,'greater than');
            bool = (Av > Bv);
        end
 
        %------------------------------------------------------------------
        function bool = eq(A, B)
            % Equality operator - compares value only
            [Av,Au,Bv,Bu] = DimVar.EqualizeInputs(A,B);
            DimVar.CheckUnits(Au,Bu,'equal to');
            bool = (Av == Bv);
        end
        
        %------------------------------------------------------------------
        function bool = le(a, b)
            % Less than or equal to operator
            bool = ~(a > b);
        end
        
        %------------------------------------------------------------------
        function bool = ge(a, b)
            % Greater than or equal to operator
            bool = ~(a < b);
        end
        
        %------------------------------------------------------------------
        function bool = ne(a, b)
            % Inequality operator
            bool = ~(a == b);
        end
        
        %------------------------------------------------------------------
        function y = mtimes(a, b)
            % Vector component-wise multiplcation
            y = a .* b; %mtimes calls times (so * calls .*)
        end
        
        %------------------------------------------------------------------
        function y = mrdivide(a, b)
            % Vector component-wise division
            y = a ./ b; %mrdivide calls rdivide (so / calls ./)
        end
        
        %------------------------------------------------------------------
        function y = mpower(a, b)
            % Vector component-wise powers
            y = a .^ b; %mpower calls power (so ^ calls .^)
        end
        
        %------------------------------------------------------------------
        function y = exp(A)
            % Exponential function
            y = DimVar.EvalDimlessFcn(A,@exp);
        end
        
        %------------------------------------------------------------------
        function y = sqrt(A)
            % Square root
            y = A .^ 0.5;
        end
        
        %------------------------------------------------------------------
        function y = log2(A)
            % Base 2 logarithm
            y = DimVar.EvalDimlessFcn(A,@log2);
        end
        
        %------------------------------------------------------------------
        function y = log10(A)
            % Base 10 logarithm
            y = DimVar.EvalDimlessFcn(A,@log10);
        end

        %------------------------------------------------------------------
        function y = log(A)
            % Natural logarithm
            y = DimVar.EvalDimlessFcn(A,@log);
        end
        
        %------------------------------------------------------------------
        function y = sin(A)
            % Sine function
            y = DimVar.EvalDimlessFcn(A,@sin);
        end
        
        %------------------------------------------------------------------
        function y = cos(A)
            % Cosine function
            y = DimVar.EvalDimlessFcn(A,@cos);
        end
        
        %------------------------------------------------------------------
        function y = tan(A)
            % Tangent function
            y = DimVar.EvalDimlessFcn(A,@tan);
        end
        
        %------------------------------------------------------------------
        function y = sum(A)
            % Sum function
            [Av,Au] = DimVar.EqualizeInputs(A);
            DimVar.CheckUnits(Au,Au(1),'sum');
            y = DimVar(sum(Av), Au{1});
        end
        
        %------------------------------------------------------------------
        function y = std(A)
            % Standard deviation function
            [Av,Au] = DimVar.EqualizeInputs(A);
            DimVar.CheckUnits(Au,Au(1),'std');
            y = DimVar(std(Av), Au{1});
        end
        
        %------------------------------------------------------------------
        function y = mean(A)
            % Mean function
            [Av,Au] = DimVar.EqualizeInputs(A);
            DimVar.CheckUnits(Au,Au(1),'mean');
            y = DimVar(mean(Av), Au{1});
        end
        
        %------------------------------------------------------------------
        function y = abs(A)
            % Absolute value function
            [Av,Au] = DimVar.EqualizeInputs(A);
            y = DimVar(abs(Av), Au);
        end
        
        %------------------------------------------------------------------
        function y = min(A)
            % Minimum function
            [Av,Au] = DimVar.EqualizeInputs(A);
            DimVar.CheckUnits(Au,Au(1),'min');
            y = DimVar(min(Av), Au);
        end
        
        %------------------------------------------------------------------
        function y = max(A)
            % Maximum function
            [Av,Au] = DimVar.EqualizeInputs(A);
            DimVar.CheckUnits(Au,Au(1),'max');
            y = DimVar(max(Av), Au);
        end
        
        %------------------------------------------------------------------
        function display(a)
            % Display the value and unit
            disp(num2str(a))
        end
        
        %------------------------------------------------------------------
        function disp(a)
            % Display the value and unit
            display(a)
        end
        
        %------------------------------------------------------------------
        function str = num2str(a,arg)
            % Display the value and unit
            if nargin > 1
                str = [num2str(a(1).Value,arg),' [',a(1).UnitStr,']'];
                for i = 2:numel(a)
                    str = strcat(str,[', ',num2str(a(i).Value,arg),...
                                      ' [',a(i).UnitStr,']']);
                end
            else
                str = [num2str(a(1).Value),' [',a(1).UnitStr,']'];
                for i = 2:numel(a)
                    str = strcat(str,[', ',num2str(a(i).Value),...
                                      ' [',a(i).UnitStr,']']);
                end
            end
        end
        
        %------------------------------------------------------------------
        function unitStr = get.UnitStr(self)
            % Build the formatted unit string
            numIDs = find(self.Unit>0);
            denIDs = find(self.Unit<0);
            
            baseStrs = {'kg','m','s','K','kmol'};
            unitStr = '';
            
            if isempty(numIDs)
                if isempty(denIDs)
                    unitStr = '-';
                else
                    unitStr = '1';
                end
            else
                for i = 1:length(numIDs)
                    id = numIDs(i);
                    if self.Unit(id) == 1
                        unitStr = strcat(unitStr,baseStrs{id},'-');
                    else
                        unitStr = strcat(unitStr,baseStrs{id},'^',...
                                         num2str(self.Unit(id),4),...
                                         '-');
                    end
                end
                unitStr = unitStr(1:end-1); %remove trailing '-'
            end
            
            if ~isempty(denIDs)
                unitStr = strcat(unitStr,'/');
                for i = 1:length(denIDs)
                    id = denIDs(i);
                    if self.Unit(id) == -1
                        unitStr = strcat(unitStr,baseStrs{id},'-');
                    else
                        unitStr = strcat(unitStr,baseStrs{id},'^',...
                                         num2str(-self.Unit(id),4),...
                                         '-');
                    end
                end
                unitStr = unitStr(1:end-1); %remove trailing '-'
            end
            
        end
        
    end %end methods
end %end classdef
