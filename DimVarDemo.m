clear all
clear classes
clc

% Rules for writing units:
%  A solidus '/' is the split between numerator and denominator. There is
%    no need to use multiple solidus lines or parentheses. Parentheses
%    will be ignored.
%  Powers can be written with or without the '^'
%  Unit components are separated by hyphens '-'
%  Inverse units can use a '1/x' or 'x^-1' notation
%  Temperatures are tricky, you must indicate if they are relative or they
%    will be converted to absolute.


%% Basic scalar usage demonstration
k1 = DimVar(16,'W/m-K');
L1 = DimVar(1,'in');
A1 = DimVar(1,'ft^2');
DT1 = DimVar(20,'C','Relative');  % DT is relative, don't add 273.15 K

k2 = DimVar(4,'BTU-in/hr-ft^2-F');
L2 = DimVar(5,'mm');
A2 = DimVar(10,'cm^2');
DT2 = DimVar(500,'R') - DimVar(200,'K');

Q1 = k1*A1/L2*DT1;
Q2 = k2*A2/L2*DT2;

%% Basic unit conversions
Q1_btu_per_hr = Q1.Convert('BTU/hr');

%% Operation checks
try
    test = A1 + L1;
catch err
    disp(err)
end

% Do some legal operations
x = A1*L1;
y = A1^(L2/L1);
z = L1 + sqrt(A1);
w = z/L1;

%% Complete array and scalar function checks

v{1} = DimVar(0:1:4,'in');
v{2} = [DimVar(1,'in'), DimVar(10,'m'), DimVar(30,'ft');
        DimVar(1,'in'), DimVar(10,'m'), DimVar(30,'mm')];
v{3} = [DimVar(1,'in'), DimVar(10,'C'), DimVar(30,'BTU')];

s1 = DimVar(1,'m');
s2 = DimVar(1,'m2');

for i = 1:2
    v{i}+s1;
    v{i}-s1; %#ok<*MNEFF>
    
    v{i}.*s1; %#ok<*VUNUS>
    v{i}./s1;
    v{i}.*s2;
    v{i}./s2;
    v{1}.^(z/L1);
    sqrt(v{i});
    sin(v{i}./s1);
    cos(v{i}./s1);
    tan(v{i}./s1);
    exp(v{i}./s1);
    log(v{i}./s1);
    log10(v{i}./s1);
    log2(v{i}./s1);
    mean(v{i});
    std(v{i});
    sum(v{i});
end

v{3}.*s1;
v{3}.*s2;
v{3}./s1;
v{3}./s2;

%% Combine with the UC class
k = DimVar(UC(16,2),'W/m-K');
L = DimVar(UC(5,1),'mm');
A = DimVar(UC(10,1),'cm^2');
DT = DimVar(500,'R') - DimVar(200,'K');

Q = k*A/L*DT;
fprintf('Q = %s\n',num2str(Q,4));