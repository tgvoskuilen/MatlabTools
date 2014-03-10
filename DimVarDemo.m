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

try
    test = A1 + L1;
catch err
    disp(err)
end

% Do some legal operations
x = A1*L1;
y = A1^(L2/L1);
z = L1 + sqrt(A1);

P = DimVar(0:1:10,'bar');
p0 = DimVar(1,'atm');

Pr = P/p0;
disp(P)
dP = P-p0;