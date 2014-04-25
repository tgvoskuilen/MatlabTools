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



%------------------------------------------------------------------------------
% Test the various functions of the UC class (not comprehensive!)

clear all
close all
clc


% This script tests all the overloaded functions and methods in UC
% Giving a name to a UC is not required, but is recommended. The name
% will be carried through calculations so you can see its effect on later
% UC objects.

fprintf('Testing variable construction\n');
x = UC([10 12 -12],[1 3 4],'x');  %vector values, vector errors
y = UC([1 2 3 4]', 2, 'y');       %vector values, scalar error
z = UC(15, 10, 'z');              %scalar value, scalar error
s = 4.5;                          %a normal scalar (not a UC)

fprintf('Testing basic math and vector operations\n');
a = y(1)*(z+15);
c = x + z;
d = x - z;
e = x * z;
f = x / z;
g = x .^ z;
h = z .^ x;
j = x ^ 2;
xpy = x + z;
xps = x + s;

fprintf('Testing self-correlation accuracy (should all be 50 +/- 30)\n');
a = UC(100,1,'a');
b = UC(10,4,'b');
c = UC(95,2,'c');

% These should be the same if correlations are handled properly
p1 = b*(a-c) %#ok<NOPTS>
p2 = a*b - c*b %#ok<NOPTS>
i1 = a*b;
i2 = c*b;
p3 = i1-i2 %#ok<NOPTS>

% Slightly more complicated self-correlation test
fprintf('Testing self-correlation accuracy (dnudd should be -0.3183)\n');
d = UC(1,0.8,'d');
n1 = UC(1,0.1,'n1');
n2 = UC(-1,0.1,'n2');
x1 = atan(n1/d)/pi + 0.5;
x2 = atan(n2/d)/pi + 0.5;
nu = x1 - x2;
nu.Inputs
nu.dydx  %dnu/dd should be -1/pi (-0.3183)

fprintf('Testing duplicate name treatment (should not have 0 error)\n');
a1 = UC(10,9,'a');
a2 = UC(10,1,'a');
d = a1 - a2 %#ok<NOPTS>

fprintf('Testing error propogation through several operations\n');
v1 = sqrt(x + z);
v2 = exp(z);
v3 = (v1 * v2)^2;
fprintf('  v1(1) = %s\n',v1(1).Name)
fprintf('  v2 = %s\n',v2.Name)
fprintf('  v3(1) = %s\n',v3(1).Name)

% Test various overloaded functions
fprintf('Testing overloaded functions\n')
ex=exp(x);
sx=sin(x);
sy=sin(y);
cx=cos(x);
cy=cos(y);
sqrx=sqrt(abs(x));
sqry=sqrt(y);
maxx=max(x);
maxy=max(y);
minx=min(x);
miny=min(y);
sumx=sum(x);
sumy=sum(y);
meanx=mean(x);
meany=mean(y);


% Make a linear projection using UC vectors
% x and y are some vectors with random uncertainty, and we want to find
% the slope m and intercept b of y = m*x+b to project y to a give
% projection point 'xp'
fprintf('Testing linear projection and polyfit\n')
x = UC(0:1:10, rand(1,11), 'x');
y = UC(3.*[x.Value] + 2 + 3.*rand(1,11), 3.*[x.Err] + 5.*rand(1,11), 'y');


xp = 12;  %This can be a normal number, or a UC value
%xp = UC(12,2,'xp'); also works
yp = linear_projection(x,y,xp);
p = polyfit(x,y,1); %this calls the special 'polyfit' in the @UC folder

% NOTE: yp above is the same value as p(1)*xp + p(2) but not the same
% uncertainty. The linear projection routine assumes the point sets are
% self correlated when doing the projection, while p(1)*xp+p(2) does not.
% Therefore, the uncertainty using linear_projection is typically lower.

fprintf('  Slope (%s) = %f +/- %f\n',p(1).Name,p(1).Value,p(1).Err);
fprintf('  Intercept (%s) = %f +/- %f\n',p(2).Name,p(2).Value,p(2).Err);

fprintf('Testing plotting\n')
% Plot the UC vectors
figure;
hold all
hD = plot(x,y);
hP = plot(xp,yp);
set(hD,'MarkerFaceColor',[0.5 0.5 0.5]);
set(hP,'Marker','s','MarkerSize',9,'MarkerFaceColor','r');
set(gca,'Box','on')
xlabel('x')
ylabel('y')
% An example using correlated uncertainties
% P1 and P2 are from the same instrument, so they are highly correlated
% with Rc = 0.99
%
% How do we find delta_P at time 'td'?
%

fprintf('Testing uncertainty correlation\n');
eP = 2;
t1 = 0:0.05:10;
t2 = 12:0.05:22;

P1 = UC(10 + 0.5*randn(size(t1)), eP, 'PT_01');
P2 = UC(8 + 0.5*randn(size(t2)),  eP, 'PT_01');
td = 11;

[Pi,mi,bi] = linear_projection(t1,P1,td);
[Pf,mf,bf] = linear_projection(t2,P2,td);
dP = Pi - Pf;


figure;
hold all
plot(t1,P1);
plot(t2,P2);

plot([0 td+1],mi.Value.*[0 td+1]+bi.Value,'--r','LineWidth',1.5);
plot([td-1 22],mf.Value.*[td-1 22]+bf.Value,'--r','LineWidth',1.5);

hi = plot(td,Pi);
hf = plot(td,Pf);
set([hi hf],'MarkerFaceColor','r');
xlim([0 22])
axis equal
