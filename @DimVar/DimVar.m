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
    
    properties (Access = private)
        Unit = [0 0 0 0 0];  % Unit array [kg m s K kmol]
    end
    
    %----------------------------------------------------------------------
    % Dependent properties (looked up from sub-structures)
    properties (Dependent = true, SetAccess = private)
        UnitStr  % String representation of unit
    end
    
    %----------------------------------------------------------------------
    % Constant properties
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
        ... Length units (km,m,cm,mm,ft,in)
            'km', {1e3,    [0 1 0 0 0]}, ...
            'm',  {1,      [0 1 0 0 0]}, ...
            'cm', {1e-2,   [0 1 0 0 0]}, ...
            'mm', {1e-3,   [0 1 0 0 0]}, ...
            'ft', {0.3048, [0 1 0 0 0]}, ...
            'in', {0.0254, [0 1 0 0 0]}, ...
        ...
        ... Time units (s,min,hr)
            's',   {1,     [0 0 1 0 0]}, ...
            'min', {60,    [0 0 1 0 0]}, ...
            'hr',  {3600,  [0 0 1 0 0]}, ...
        ...
        ... Temperature units (K,C,R,F)
            'k',   {1,             [0 0 0 1 0]}, ...
            'r',   {5/9,           [0 0 0 1 0]}, ...
            'c',   {[1 273.15],    [0 0 0 1 0]}, ...
            'f',   {[5/9 255.372], [0 0 0 1 0]}, ...
        ...
        ... Molar quantity units (mol,kmol)
            'kmol',  {1,    [0 0 0 0 1]}, ...
            'mol',   {1e-3, [0 0 0 0 1]}, ...
        ...
        ... Volume units (L,ml,cc)
            'l',  {1e-3, [0 3 0 0 0]}, ...
            'ml', {1e-6, [0 3 0 0 0]}, ...
            'cc', {1e-6, [0 3 0 0 0]}, ...
        ...
        ... Flow rate units (gpm,cfm)
            'gpm',  {1/15852,  [0 3 -1 0 0]}, ...
            'cfm',  {1/2119,   [0 3 -1 0 0]}, ...
        ...
        ... Frequency units (Hz,rpm)
            'hz',  {1,    [0 0 -1 0 0]},...
            'rpm', {1/60, [0 0 -1 0 0]},...
        ...
        ... Energy units (J,BTU,erg,cal,kWh)
            'j',   {1,          [1 2 -2 0 0]},...
            'btu', {1055.05585, [1 2 -2 0 0]},...
            'erg', {1e-7,       [1 2 -2 0 0]},...
            'cal', {4.184,      [1 2 -2 0 0]},...
            'kwh', {3.6e6,      [1 2 -2 0 0]},...
        ...
        ... Power units (W)
            'w',  {1,    [1 2 -3 0 0]},...
        ...
        ... Force units (N,lbf,dyne)
            'n',   {1,          [1 1 -2 0 0]}, ...
            'lbf', {4.44822162, [1 1 -2 0 0]}, ...
            'dyne',{1e-5,       [1 1 -2 0 0]}, ...
        ...
        ... Pressure units (psi,bar,pa,kpa,mpa,torr,mbar,atm)
            'pa',   {1,          [1 -1 -2 0 0]}, ...
            'kpa',  {1e3,        [1 -1 -2 0 0]}, ...
            'mpa',  {1e6,        [1 -1 -2 0 0]}, ...
            'bar',  {1e5,        [1 -1 -2 0 0]}, ...
            'mbar', {1e2,        [1 -1 -2 0 0]}, ...
            'torr', {133.322368, [1 -1 -2 0 0]}, ...
            'psi',  {6894.75729, [1 -1 -2 0 0]}, ...
            'atm',  {101325,     [1 -1 -2 0 0]}, ...
        ...
        ... Dynamic viscosity units (p,cp)
            'p',   {0.1,   [1 -1 -1 0 0]}, ...
            'cp',  {0.001, [1 -1 -1 0 0]}  ...
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
        function CheckUnits(dv1,dv2,opStr)
            % Check if units are equal, raise an error if they are not
            if ~all(dv1.Unit == dv2.Unit);
                error('DimVar:CheckUnits',...
                      ['Unit mismatch in "%s" operator, attempting',...
                      ' to combine %s and %s'],opStr,...
                      dv1.UnitStr,dv2.UnitStr);
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
        function str = GetString(num)
            % Convert num to a string
            eps = 1e-6;
            l = floor(num);
            str = sprintf('%d',l);

            if l ~= num
                str = strcat(str,'.');
                d = num - l;
                nd = 1;

                while abs(d) > eps && nd <= 4
                    str = strcat(str,sprintf('%1d',floor(10*d + eps)));
                    d = 10*d - floor(10*d + eps);
                    nd = nd + 1;
                end
            end
        end
        
        %------------------------------------------------------------------
        function np = ReadUnitPower(str,sgn)
            % Read a string like 'm^3' or 'm3' and get the unit and power
            
            pid = strfind(str,'^');
            
            if isempty(pid)
                str = regexprep(str,'([0-9]+)','^$1');
            end
            
            pid = strfind(str,'^');
            
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
            
            if isfield(DimVar.uTable, lower(str))
                [factor,unit] = DimVar.uTable.(lower(str));
            else
                % Return an error for unknown units
                error('DimVar:ReadUnitStr',...
                      'Unrecognized unit "%s"',str);
            end
            
        end
    end
    
    %----------------------------------------------------------------------
    methods
        
        %------------------------------------------------------------------
        function dv = DimVar(val, unit, isrel)
            % Constructor for a dimensioned variable
            
            if nargin ~= 0
                if nargin >= 2
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
                        [dv.Unit,f] = DimVar.ReadUnitStr(unit);
                        if length(f) == 2 && ~isRel
                            dv.Value = val.*f(1) + f(2);
                        else
                            dv.Value = val.*f(1);
                        end
                    else
                        if length(unit) == 5
                            dv.Unit = unit;
                            dv.Value = val;
                        else
                            error('MATLAB:DimVar',...
                                  'Invalid unit array');
                        end
                    end
                else
                    dv.Unit = [0 0 0 0 0];
                    dv.Value = val;
                end
            end
        end

        %------------------------------------------------------------------
        % Operator overloading
        %------------------------------------------------------------------
        function y = plus(A, B)
            % Addition operator
            
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end
            
            % Check units
            DimVar.CheckUnits(A,B,'plus');
            
            y = DimVar(A.Value+B.Value,A.Unit);
        end
        
        %------------------------------------------------------------------
        function y = minus(A, B)
            % Subtraction operator
            
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end

            % Check units
            DimVar.CheckUnits(A,B,'minus');
            
            y = DimVar(A.Value-B.Value,A.Unit);
        end
        
        %------------------------------------------------------------------
        function y = times(A, B)
            % Multiplcation operator
            
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end
            
            newUnit = A.Unit + B.Unit;
            y = DimVar(A.Value.*B.Value,newUnit);
        end
        
        %------------------------------------------------------------------
        function y = rdivide(A, B)
            % Division operator
            
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end

            newUnit = A.Unit - B.Unit;
            y = DimVar(A.Value./B.Value,newUnit);
        end
        
        %------------------------------------------------------------------
        function y = power(A, B)
            % Power operator
            
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end
            
            % power must be dimensionless
            if max(abs(B.Unit)) > 0
                error('DimVar:power',...
                      'Exponent must be dimensionless');
            end
            
            newUnit = A.Unit.*B.Value;
            y = DimVar(A.Value.^B.Value,newUnit);
        end
       
        %------------------------------------------------------------------
        function bool = lt(A, B)
            % Less than operator
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end
            
            % Check units
            DimVar.CheckUnits(A,B,'less than');
            
            bool = ([A.Value] < [B.Value]);
        end
        
        %------------------------------------------------------------------
        function bool = gt(A, B)
            % Greater than operator
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end
            
            % Check units
            DimVar.CheckUnits(A,B,'greater than');
            
            bool = ([A.Value] > [B.Value]);
        end
        
        %------------------------------------------------------------------
        function neg = uminus(A)
            % Negation operator
            neg = A;
            neg.Value = -neg.Value;
        end
        
        %------------------------------------------------------------------
        function bool = eq(A, B)
            % Equality operator - compares value only
            if ~isa(A,'DimVar')
                A = DimVar(A);
            end
            if ~isa(B,'DimVar')
                B = DimVar(B);
            end
            
            % Check units
            DimVar.CheckUnits(A,B,'equal to');
            
            bool = ([A.Value] == [B.Value]);
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
        function display(a)
            % Display the value and unit
            disp([num2str(a.Value),' [',a.UnitStr,']'])
        end
        
        %------------------------------------------------------------------
        function disp(a)
            % Display the value and unit
            display(a)
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
                                         DimVar.GetString(self.Unit(id)),...
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
                                         DimVar.GetString(-self.Unit(id)),...
                                         '-');
                    end
                end
                unitStr = unitStr(1:end-1); %remove trailing '-'
            end
            
        end
        
    end %end methods
end %end classdef
