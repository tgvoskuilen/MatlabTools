function p = polyfit(x,y,n)
    % Polynomial fitting, 0th and 1st order only
    
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

    if n > 1
        error('Polyfit is not compatible with UC for polynomial order > 1');
    else
        if ~isa(x,'UC')
            x = UC(x,0,'polyfitX');
        end
        if ~isa(y,'UC')
            y = UC(y,0,'polyfitY');
        end
        
        if n == 0
            p = mean(y);
        else
            [~, m, b] = linear_projection(x,y,0);
            p = [m b];
        end
    end
