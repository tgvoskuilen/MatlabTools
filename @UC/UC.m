classdef UC
    % This class is for handling values with an associated uncertainty
    %
    % It is designed to be a "stand-in" replacement for numeric data in
    % Matlab that carries an uncertainty value through your operations
    % by overloading basic math operations like addition, subtraction,
    % etc...
    %
    % For example, to create two UC variables, you could do
    %
    %   x = UC(1,3,'x');  % value is 1, uncertainty is 3, name is 'x'
    %   y = UC(10,1,'y'); % value is 10, uncertainty is 1, name is 'y'
    %
    % You can then use x and y as you would normal Matlab variables, so
    %
    %   z = x + y;
    %   w = z^(x+y);
    %
    % would propogate the original uncertainty through to z and w.
    
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
    properties (SetAccess = protected) %You may not change these
        Name = '';  % Variable name
        Value = 0;  % Value
        Err = 0;    % Value uncertainty
        Contrib = {}; % List of contributors to this variable
        Hash = -1;  % Hash value (unique ID number for this set of data)
    end
    
    %----------------------------------------------------------------------
    properties (Access = private)
        Err_r = 0;  % Random error (currently not used)
    end
    %----------------------------------------------------------------------
    % Private static functions
    methods(Static, Access = private)
        
        %------------------------------------------------------------------
        function y = UnaryFunction(x,f,dfdx)
            y = UC(f([x.Value]), abs(dfdx([x.Value])).*[x.Err]);
            for i = 1:length(x)
                y(i).Name = strcat(func2str(f),'(',x(i).Name,')');
                y(i).Contrib = x(i).Contrib;
            end
            y = reshape(y,size(x)); 
        end
        
        %------------------------------------------------------------------
        function [Av,Ae,Ah,Bv,Be,Bh] = EqualizeInputs(A,B)
            % Extract value and error arrays from inputs
            if isa(A,'UC')
                Av = reshape([A.Value],size(A));
                Ah = reshape([A.Hash],size(A));
                Ae = reshape([A.Err],size(A));
            else
                Av = A;
                Ae = zeros(size(A));
                Ah = -ones(size(A));
            end
            
            if exist('B','var')
                if isa(B,'UC')
                    Bv = reshape([B.Value],size(B));
                    Bh = reshape([B.Hash],size(B));
                    Be = reshape([B.Err],size(B));
                else
                    Bv = B;
                    Be = zeros(size(B));
                    Bh = -ones(size(B));
                end
            end
        end
        
    end
    
    
    %----------------------------------------------------------------------
    methods (Access = private)
        
        %------------------------------------------------------------------
        function y = AssignContrib(obj, A, B, fA, fB, opString)
            % Determine the fractional contribution to uncertainty from separate inputs
            
            y = obj;
            for i = 1:numel(y)
                
                if i > numel(A)
                    Ai = A;
                else
                    Ai = A(i);
                end
                
                if i > numel(B)
                    Bi = B;
                else
                    Bi = B(i);
                end

                % Technically the '^' operator doesn't need (), but it's
                % more clear that way about order of operations
                if isa(Ai,'UC')
                    AName = Ai.Name;
                else
                    AName = num2str(Ai);
                end
                if isa(Bi,'UC')
                    BName = Bi.Name;
                else
                    BName = num2str(Bi);
                end
                
                Ap = strfind(AName,'+');
                Am = strfind(AName,'m');
                Bp = strfind(BName,'+');
                Bm = strfind(BName,'m');
                
                switch opString
                    case {'+','-'}
                        y(i).Name = strcat(AName,opString,BName);
                    otherwise
                        if isempty(Ap) && isempty(Am)
                            ANameGroup = AName;
                        else
                            ANameGroup = strcat('(',AName,')');
                        end
                        
                        if isempty(Bp) && isempty(Bm)
                            BNameGroup = BName;
                        else
                            BNameGroup = strcat('(',BName,')');
                        end
                        
                        y(i).Name = strcat(ANameGroup,opString,BNameGroup);
                end
                
                if isnan(fA(i)) || isnan(fB(i))
                    y(i).Contrib = {};
                elseif fA(i) == 0 && fB(i) ~= 0
                    y(i).Contrib = Bi.Contrib;
                elseif fB(i) == 0 && fA(i) ~= 0
                    y(i).Contrib = Ai.Contrib;
                else

                    fyFull = [cell2mat(Ai.Contrib(2,:)).*fA(i) ...
                              cell2mat(Bi.Contrib(2,:)).*fB(i)];
                    yContribFull = [Ai.Contrib(1,:) Bi.Contrib(1,:)];
                    
                    y(i).Contrib = {};
                    Nc = length(unique(yContribFull));
                    y(i).Contrib(1,:) = unique(yContribFull);
                    y(i).Contrib(2,:) = num2cell(zeros(1,Nc));

                    for j = 1:Nc
                        y(i).Contrib{2,j} = ...
                            sum(fyFull(strcmpi(yContribFull,y(i).Contrib{1,j})));
                    end
                end
            end
        end 
        
    end
    
    %----------------------------------------------------------------------
    %Define class methods
    methods
        %------------------------------------------------------------------
        %Constructor function
        function uc = UC(val, err, name, hash)
            [~,fldr] = fileparts(pwd);
            if strcmpi(fldr,'@UC')
                error('MATLAB:UC',...
                      'Do not work inside the "@UC" folder');
            end
            
            if nargin ~= 0
                hash_stream = RandStream('mt19937ar','Seed','shuffle');
                if nargin >= 2
                    %Read values
                    if ~isequal(size(val),size(err))
                        if all(size(err) == 1)
                            err = err.*ones(size(val));
                        else
                            error('Value and Error must be the same size')
                        end
                    end
                    
                    %Set hash
                    if ~exist('hash','var')
                        hash = rand(hash_stream,1,1);
                    end
                    
                    %Set name
                    if ~exist('name','var')
                        name = '';
                    end
                   
                    
                elseif nargin == 1
                    err = val .* 0;
                    hash = rand(hash_stream,1,1);
                    name = '';
                end

                if numel(hash) ~= numel(val)
                    hash = ones(size(val)).*hash;
                end
                
                uc(numel(val)) = UC;
                for i=1:numel(val)
                    uc(i).Value = val(i);
                    uc(i).Err = err(i);
                    tmp = val(i)+err(i); %#ok<NASGU> %make sure they are compatible
                    uc(i).Err_r = 0;
                    uc(i).Hash = hash(i);
                    if isempty(name)
                        uc(i).Name = num2str(val(i));
                    else
                        if numel(val) > 1
                            uc(i).Name=strcat(name,'[',num2str(i),']');
                        else
                            uc(i).Name=name;
                        end
                    end
                    uc(i).Contrib = {uc(i).Name; 1};
                end
                uc = reshape(uc,size(val));
            end
        end

        function val = double(self)
            % Define conversion to double
            val = [self.Value];
            val = reshape(val,size(self));
        end
        
        %------------------------------------------------------------------
        % Operator overloading
        %------------------------------------------------------------------
        function y = plus(A, B)
            % Addition operator
            [Av,Ae,Ah,Bv,Be,Bh] = UC.EqualizeInputs(A,B);
            rhoAB = Ah==Bh;
            yv = Av + Bv;
            ye = sqrt(Ae.^2 + Be.^2 + 2.*rhoAB.*Ae.*Be);
            y = UC(yv, ye, '', Ah+Bh);
            
            % Fractional contributions, fA + fB = 1
            fA = Ae.^2 ./ ye.^2;
            fB = Be.^2 ./ ye.^2;
            
            y = AssignContrib(y, A, B, fA, fB, '+');
        end
        
        %------------------------------------------------------------------
        function y = minus(A, B)
            % Subtraction operator
            [Av,Ae,Ah,Bv,Be,Bh] = UC.EqualizeInputs(A,B);
            rhoAB = Ah==Bh;
            yv = Av - Bv;
            ye = sqrt(Ae.^2 + Be.^2 - 2.*rhoAB.*Ae.*Be);
            y = UC(yv, ye, '', Ah-Bh);
            
            % Fractional contributions, fA + fB = 1
            fA = Ae.^2 ./ ye.^2;
            fB = Be.^2 ./ ye.^2;
            
            y = AssignContrib(y, A, B, fA, fB, '-');
        end
        
        %------------------------------------------------------------------
        function y = times(A, B)
            % Multiplcation operator
            [Av,Ae,Ah,Bv,Be,Bh] = UC.EqualizeInputs(A,B);
            rhoAB = Ah==Bh;
            yv = Av.*Bv;
            ye = sqrt((Bv.*Ae).^2 + (Av.*Be).^2 +...
                      2.*rhoAB.*Av.*Bv.*Ae.*Be);
            y = UC(yv, ye, '', Ah.*Bh);
            
            % Fractional contributions, fA + fB = 1
            fA = (Ae.*Bv).^2 ./ ye.^2;
            fB = (Av.*Be).^2 ./ ye.^2;
            
            y = AssignContrib(y, A, B, fA, fB, '*');
        end
        
        %------------------------------------------------------------------
        function y = rdivide(A, B)
            % Division operator
            [Av,Ae,Ah,Bv,Be,Bh] = UC.EqualizeInputs(A,B);
            rhoAB = Ah==Bh;
            yv = Av./Bv;
            ye = sqrt((Ae./Bv).^2 + (Av./Bv.^2.*Be).^2 - ...
                      2.*rhoAB.*Ae.*Be./Av./Bv);
            y = UC(yv, ye, '', Ah./Bh);
            
            % Fractional contributions, fA + fB = 1
            fA = (Ae./Bv).^2 ./ ye.^2;
            fB = (Av./Bv.^2.*Be).^2 ./ ye.^2;
            
            y = AssignContrib(y, A, B, fA, fB, '/');
        end
        
        %------------------------------------------------------------------
        function y = power(A, B)
            % Power operator
            [Av,Ae,Ah,Bv,Be,Bh] = UC.EqualizeInputs(A,B);
            rhoAB = Ah==Bh;
            yv = Av.^Bv;
            ye = sqrt((Bv.*Av.^(Bv-1).*Ae).^2 + ...
                      (log(Av).*yv.*Be).^2 + ...
                      2.*rhoAB.*Bv.*Av.^(Bv.*(Bv-1)).*log(Av).*Ae.*Be);
            
            y = UC(yv, ye, '', Ah.^Bh);
            
            % Fractional contributions, fA + fB = 1
            fA = (Bv.*Av.^(Bv-1).*Ae).^2 ./ ye.^2;
            fB = (log(Av).*yv.*Be).^2 ./ ye.^2;
            
            y = AssignContrib(y, A, B, fA, fB, '^');
        end
       
        %------------------------------------------------------------------
        function bool = lt(A, B)
            % Less than operator
            if ~isa(A,'UC')
                A = UC(A);
            end
            if ~isa(B,'UC')
                B = UC(B);
            end
            bool = ([A.Value] < [B.Value]);
        end
        
        %------------------------------------------------------------------
        function bool = gt(A, B)
            % Greater than operator
            if ~isa(A,'UC')
                A = UC(A);
            end
            if ~isa(B,'UC')
                B = UC(B);
            end
            bool = ([A.Value] > [B.Value]);
        end
        
        %------------------------------------------------------------------
        function neg = uminus(A)
            % Negation operator
            neg = A;
            neg.Value = -neg.Value;
        end
        
        %------------------------------------------------------------------
        function pos = uplus(A)
            % Unary + operator
            pos = A;
        end
        
        %------------------------------------------------------------------
        function bool = eq(A, B)
            % Equality operator - compares value only
            if ~isa(A,'UC')
                A = UC(A);
            end
            if ~isa(B,'UC')
                B = UC(B);
            end
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
        function y = mtimes(A, B)
            % Matrix/vector multiplcation ('*' operator)
            
            % More efficient, but does not calculate Contrib
%             
%             [Av,Ae,Ah,Bv,Be,Bh] = UC.EqualizeInputs(A,B);
%             
%             yv = Av*Bv;
%             ye = sqrt((Av.^2)*(Be.^2) + (Ae.^2)*(Bv.^2));
%             y = UC(yv, ye, '', Ah*Bh);
%             
%             % Fractional contributions, fA + fB = 1
%             fA = ((Ae.^2)*(Bv.^2)) ./ ye.^2;
%             fB = ((Av.^2)*(Be.^2)) ./ ye.^2;

            

            % Loop approach calculates contrib
            sA = size(A);
            sB = size(B);
            
            if length(sA) > 2 || length(sB) > 2
                error('UC:mtimes',...
                      'Inputs must be 2-D or lower');
            end
            
            y(1:sA(1),1:sB(2)) = UC;
            for i = 1:sA(1)
                for j = 1:sB(2)
                    y(i,j) = A(i,1).*B(1,j);
                    for k = 2:sA(2)
                        y(i,j) = y(i,j) + A(i,k).*B(k,j);
                    end
                end
            end
        end
        
        %------------------------------------------------------------------
        function y = mrdivide(A, B)
            % Matrix division
            % y = A * inv(B)
            y = A ./ B;
            %error('UC:mrdivide',...
            %      'UC matrix inversion is not yet supported');
        end
        
        %------------------------------------------------------------------
        function y = mpower(A, B)
            % Matrix power operator
            y = A .^ B;
            %error('UC:mpower',...
            %      'UC matrix power is not yet supported');
        end
        
        %------------------------------------------------------------------
        function display(a)
            % Display the value and uncertainty
            disp(num2str(a));
        end
        
        %------------------------------------------------------------------
        function y = abs(x)
            % Absolute value
            y = UC.UnaryFunction(x, @abs, @(v) 1);
        end
        
        %------------------------------------------------------------------
        function y = cos(x)
            % Cosine function
            y = UC.UnaryFunction(x, @cos, @sin );
        end
        
        %------------------------------------------------------------------
        function y = sin(x)
            % Sine function
            y = UC.UnaryFunction(x, @sin, @cos );
        end
        
        %------------------------------------------------------------------
        function y = tan(x)
            % Tangent function
            y = UC.UnaryFunction(x, @tan, @(v) sec(v).^2);
        end
        
        %------------------------------------------------------------------
        function y = csc(x)
            % Cosecant function
            y = UC.UnaryFunction(x, @csc, @(v) csc(v).*cot(x));
        end
        
        %------------------------------------------------------------------
        function y = sec(x)
            % Secant function
            y = UC.UnaryFunction(x, @sec, @(v) sec(v).*tan(x));
        end
        
        %------------------------------------------------------------------
        function y = cot(x)
            % Cotangent function
            y = UC.UnaryFunction(x, @cot, @(v) csc(v).^2);
        end
        
        %------------------------------------------------------------------
        function y = atan(x)
            % Inverse tangent function
            y = UC.UnaryFunction(x, @atan, @(v) 1./(1+v.^2));
        end
         
        %------------------------------------------------------------------
        function y = asin(x)
            % Inverse sine function
            y = UC.UnaryFunction(x, @asin, @(v) 1./sqrt(1-v.^2));
        end
        
        %------------------------------------------------------------------
        function y = acos(x)
            % Inverse cosine function
            y = UC.UnaryFunction(x, @acos, @(v) 1./sqrt(1-v.^2));
        end
        
        %------------------------------------------------------------------
        function y = asec(x)
            % Inverse secant function
            y = UC.UnaryFunction(x, @asec, @(v) 1./(v.*sqrt(v.^2-1)));
        end
        
        %------------------------------------------------------------------
        function y = acsc(x)
            % Inverse cosecant function
            y = UC.UnaryFunction(x, @acsc, @(v) 1./(v.*sqrt(v.^2-1)));
        end
        
        %------------------------------------------------------------------
        function y = acot(x)
            % Inverse cotangent function
            y = UC.UnaryFunction(x, @acot, @(v) 1./(1+v.^2));
        end
        
        %------------------------------------------------------------------
        function y = sqrt(x)
            % Square root
            y = UC.UnaryFunction(x, @sqrt, @(v) 0.5./v.^0.5);
        end
        
        %------------------------------------------------------------------
        function y = exp(x)
            % Exponential function 
            y = UC.UnaryFunction(x, @exp, @(v) exp(v));
        end
        
        %------------------------------------------------------------------
        function y = log(x)
            % Natural log function 
            y = UC.UnaryFunction(x, @log, @(v) 1./v);
        end
        
        %------------------------------------------------------------------
        function y = log10(x)
            % Log base 10 function 
            y = UC.UnaryFunction(x, @log10, @(v) 1./(v.*log(10)));
        end
        
        %------------------------------------------------------------------
        function y = log2(x)
            % Log base 2 function 
            y = UC.UnaryFunction(x, @log2, @(v) 1./(v.*log(2)));
        end
        
        %------------------------------------------------------------------
        function y = sum(x)
            % Array sum function (does not exactly mimic sum for matrices) 
            y = UC(sum([x.Value]), ...
                   sqrt(sum([x.Err].^2)), ...
                   strcat('sum(',x(1).Name,')'));
        end
        
        %------------------------------------------------------------------
        function y = mean(x)
            % Array mean function (does not exactly mimic mean for matrices) 
            y = UC(mean([x.Value]), ...
                   sqrt(sum([x.Err].^2))./numel(x), ...
                   strcat('mean(',x(1).Name,')'));
        end
        
        %------------------------------------------------------------------
        function y = min(x)
            % Array min function (does not exactly mimic min for matrices) 
            y = x([x.Value] == min([x.Value]));
        end
        
        %------------------------------------------------------------------
        function y = max(x)
            % Array max function (does not exactly mimic max for matrices) 
            y = x([x.Value] == max([x.Value]));
        end
        
        %------------------------------------------------------------------
        function str = num2str(a,arg)
            % Generate string of value and uncertainty
            if nargin > 1
                str = [num2str(a(1).Value,arg),' ',char(177),' ',...
                       num2str(a(1).Err,arg)];
                for i = 2:numel(a)
                    str = strcat(str,[', ',num2str(a(i).Value,arg),...
                                      ' ',char(177),' ',...
                                      num2str(a(i).Err,arg)]);
                end
            else
                str = [num2str(a(1).Value),' ',char(177),' ',...
                       num2str(a(1).Err)];
                for i = 2:numel(a)
                    str = strcat(str,[', ',num2str(a(i).Value),...
                                      ' ',char(177),' ',...
                                      num2str(a(i).Err)]);
                end
            end
        end
        
        %-----------------------------------------------------------------
        function hash(a)
            % Display the component hash
            disp([a.Hash]);
        end
        
    end %end methods
end %end class
