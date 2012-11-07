classdef UC
    % This class is for handling values with an associated uncertainty

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


    %----------------------------------------------------------------------
    properties (SetAccess = protected) %You may not change these
        Name = '';
        Value = 0;  %Value
        Err = 0;    %Bias error
        Err_r = 0;  %Random error
        Hash = -1;  %Hash value
        Contrib = {}; %List of contributors to this variable
        Frac = []; %Fractional error controbutions from contributors
    end
    
    %Define class methods
    methods
        %------------------------------------------------------------------
        %Constructor function
        function uc = UC(val, err, name, hash)
            if nargin ~= 0
                hash_stream = RandStream('mt19937ar','Seed',sum(100*clock));
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

                if length(hash) ~= length(val)
                    hash = ones(size(val)).*hash;
                end
                
                m = size(val,1);
                n = size(val,2);
                uc(m,n) = UC;
                for i=1:m
                    for j=1:n
                        uc(i,j).Value = val(i,j);
                        uc(i,j).Err = err(i,j);
                        uc(i,j).Err_r = 0;
                        uc(i,j).Hash = hash(i,j);
                        if isempty(name)
                            uc(i,j).Name = num2str(val(i,j));
                        else
                            if m*n > 1
                                uc(i,j).Name=strcat(name,'(',num2str(i*j),')');
                            else
                                uc(i,j).Name=name;
                            end
                        end
                        uc(i,j).Contrib = {uc(i,j).Name};
                        uc(i,j).Frac = 1;
                    end
                end
            end
        end
        
        
        function y = AssignContrib(obj, A, B, fA, fB, opString)
            
            y = obj;
                       
            for i = 1:length(y)
                % Technically the '^' operator doesn't need (), but it's
                % more clear that way about order of operations
                y(i).Name = strcat('(',A(i).Name,opString,B(i).Name,')');
                
                if fA(i) == 0 && fB(i) ~= 0
                    y(i).Contrib = B(i).Contrib;
                    y(i).Frac = B(i).Frac;
                elseif fB(i) == 0 && fA(i) ~= 0
                    y(i).Contrib = A(i).Contrib;
                    y(i).Frac = A(i).Frac;
                else
                    fyFull = [[A(i).Frac].*fA(i) [B(i).Frac].*fB(i)];
                    yContribFull = [A(i).Contrib B(i).Contrib];
                    
                    y(i).Contrib = unique(yContribFull);
                    y(i).Frac = zeros(size(y(i).Contrib));

                    for j = 1:length(y(i).Frac)
                        y(i).Frac(j) = ...
                            sum(fyFull(strcmpi(yContribFull,y(i).Contrib{j})));
                    end
                end
            end
            
            
        end
        
        %------------------------------------------------------------------
        % Operator overloading
        %------------------------------------------------------------------
        function y = plus(A, B)
            if ~strcmp(class(A),'UC')
                A = UC(A);
            end
            if ~strcmp(class(B),'UC')
                B = UC(B);
            end
            
            rhoAB = [A.Hash]==[B.Hash];
            
            ym = [A.Value] + [B.Value];
            ye = sqrt([A.Err].^2 + [B.Err].^2 + 2*rhoAB.*[A.Err].*[B.Err]);
            yhash = [A.Hash] + [B.Hash];
            
            y = UC(ym, ye, '', yhash);
            
            % Make A and B vectors of the same length
            if length(A) == 1 && length(B) > 1
                A(size(B)) = A;
            end

            if length(B) == 1 && length(A) > 1
                B(size(A)) = B;
            end

            % Loop through elements of y and assign contrib to each
            fA = [A.Err].^2 ./ ye.^2;
            fB = [B.Err].^2 ./ ye.^2;
            %fA(isnan(fA)) = 0;
            %fB(isnan(fB)) = 0;
            
            y = AssignContrib(y, A, B, fA, fB, '+');
        end
        
        %------------------------------------------------------------------
        function y = minus(A, B)
            if ~strcmp(class(A),'UC')
                A = UC(A);
            end
            if ~strcmp(class(B),'UC')
                B = UC(B);
            end

            rhoAB = [A.Hash]==[B.Hash];
            
            ym = [A.Value] - [B.Value];
            ye = sqrt([A.Err].^2 + [B.Err].^2 - 2*rhoAB.*[A.Err].*[B.Err]);
            yhash = [A.Hash] - [B.Hash];
            
            y = UC(ym, ye, '', yhash);
            
            % Make A and B vectors of the same length
            if length(A) == 1 && length(B) > 1
                A(size(B)) = A;
            end

            if length(B) == 1 && length(A) > 1
                B(size(A)) = B;
            end

            % Loop through elements of y and assign contrib to each
            fA = [A.Err].^2 ./ ye.^2;
            fB = [B.Err].^2 ./ ye.^2;
            %fA(isnan(fA)) = 0;
            %fB(isnan(fB)) = 0;
            
            y = AssignContrib(y, A, B, fA, fB, '-');

        end
        
        %------------------------------------------------------------------
        function y = times(A, B)
            if ~strcmp(class(A),'UC')
                A = UC(A);
            end
            if ~strcmp(class(B),'UC')
                B = UC(B);
            end
      
            rhoAB = [A.Hash]==[B.Hash];
            
            ym = [A.Value] .* [B.Value];
            ye = sqrt(([B.Value].*[A.Err]).^2 + ...
                      ([A.Value].*[B.Err]).^2 + ...
                      2.*rhoAB.*[A.Value].*[B.Value].*[A.Err].*[B.Err]);
            yhash = [A.Hash] .* [B.Hash];
                      
            y = UC(ym, ye, '', yhash);
            
            % Make A and B vectors of the same length
            if length(A) == 1 && length(B) > 1
                A(size(B)) = A;
            end

            if length(B) == 1 && length(A) > 1
                B(size(A)) = B;
            end

            % Loop through elements of y and assign contrib to each
            fA = ([A.Err].*[B.Value]).^2 ./ ye.^2;
            fB = ([B.Err].*[A.Value]).^2 ./ ye.^2;
            %fA(isnan(fA)) = 0;
            %fB(isnan(fB)) = 0;
            
            y = AssignContrib(y, A, B, fA, fB, '*');

        end
        
        %------------------------------------------------------------------
        function y = rdivide(A, B)
            if ~strcmp(class(A),'UC')
                A = UC(A);
            end
            if ~strcmp(class(B),'UC')
                B = UC(B);
            end
                          
            rhoAB = [A.Hash]==[B.Hash];
            
            ym = [A.Value] ./ [B.Value];
            ye = sqrt(([A.Err] ./ [B.Value]).^2 + ...
                      ([A.Value] ./ [B.Value] .^2 .* [B.Err]).^2 - ...
                      2.*rhoAB.*[A.Err].*[B.Err]./[A.Value]./[B.Value]);
            yhash = [A.Hash] ./ [B.Hash];        
            
            y = UC(ym, ye, '', yhash);
            
            % Make A and B vectors of the same length
            if length(A) == 1 && length(B) > 1
                A(size(B)) = A;
            end

            if length(B) == 1 && length(A) > 1
                B(size(A)) = B;
            end

            % Loop through elements of y and assign contrib to each
            fA = ([A.Err]./[B.Value]).^2 ./ ye.^2;
            fB = ([A.Value]./[B.Value].^2.*[B.Err]).^2 ./ ye.^2;
            %fA(isnan(fA)) = 0;
            %fB(isnan(fB)) = 0;
            
            y = AssignContrib(y, A, B, fA, fB, '/');

        end
        
        %------------------------------------------------------------------
        function y = power(A, B)
            if ~strcmp(class(A),'UC')
                A = UC(A);
            end
            if ~strcmp(class(B),'UC')
                B = UC(B);
            end
            
            rhoAB = [A.Hash]==[B.Hash];
            
            ym = [A.Value] .^ [B.Value];
            ye = sqrt(([B.Value].*[A.Value].^([B.Value] - 1).*[A.Err]).^2 ...
                    + (log([A.Value]).*ym.*[B.Err]).^2 + ...
                    2.*rhoAB.*[B.Value].*[A.Value].^([B.Value].*([B.Value]-1))...
                    .*log([A.Value]).*[A.Err].*[B.Err]);
            yhash = [A.Hash] .^ [B.Hash];
            
            y = UC(ym, ye, '', yhash);
            
            % Make A and B vectors of the same length
            if length(A) == 1 && length(B) > 1
                A(size(B)) = A;
            end

            if length(B) == 1 && length(A) > 1
                B(size(A)) = B;
            end

            % Loop through elements of y and assign contrib to each
            fA = ([B.Value].*[A.Value].^([B.Value] - 1).*[A.Err]).^2 ./ ye.^2;
            fB = (log([A.Value]).*ym.*[B.Err]).^2 ./ ye.^2;
            %fA(isnan(fA)) = 0;
            %fB(isnan(fB)) = 0;
            
            y = AssignContrib(y, A, B, fA, fB, '^');
        end
       
        %------------------------------------------------------------------
        function bool = lt(a, b)
            if ~strcmp(class(a),'UC')
                a = UC(a);
            end
            if ~strcmp(class(b),'UC')
                b = UC(b);
            end
            bool = ([a.Value] < [b.Value]);
        end
        
        %------------------------------------------------------------------
        function bool = gt(a, b)
            if ~strcmp(class(a),'UC')
                a = UC(a);
            end
            if ~strcmp(class(b),'UC')
                b = UC(b);
            end
            bool = ([a.Value] > [b.Value]);
        end
        
        %------------------------------------------------------------------
        function bool = eq(a, b)
            if ~strcmp(class(a),'UC')
                a = UC(a);
            end
            if ~strcmp(class(b),'UC')
                b = UC(b);
            end
            bool = ([a.Value] == [b.Value] & [a.Err] == [b.Err]);
        end
        
        %------------------------------------------------------------------
        function bool = le(a, b)
            bool = ~(a > b);
        end
        
        %------------------------------------------------------------------
        function bool = ge(a, b)
            bool = ~(a < b);
        end
        
        %------------------------------------------------------------------
        function bool = ne(a, b)
            bool = ~(a == b);
        end
        
        %------------------------------------------------------------------
        function y = mtimes(a, b)
            y = a .* b; %mtimes calls times (so * calls .*)
        end
        
        %------------------------------------------------------------------
        function y = mrdivide(a, b)
            y = a ./ b; %mrdivide calls rdivide (so / calls ./)
        end
        
        %------------------------------------------------------------------
        function y = mpower(a, b)
            y = a .^ b; %mpower calls power (so ^ calls .^)
        end
        
        %------------------------------------------------------------------
        function display(a)
            disp([num2str([a.Value]),' ',char(177),' ',num2str([a.Err])]);
        end
        
        %-----------------------------------------------------------------
        function hash(a)
            disp([a.Hash]);
        end
        
    end %end methods
end %end class
