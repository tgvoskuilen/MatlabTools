Matlab Tools
============

My custom matlab scripts and classes. To clone this repository into your
Matlab folder (assuming it is at `~/Personal/MATLAB`), enter the following
commands at a UNIX shell (check that you have `git` installed first by typing
`which git`):

    cd ~/Personal/MATLAB
    git clone git://github.com/tgvoskuilen/MatlabTools.git
    
To update your versions of the code if you have already cloned the repository:

    cd ~/Personal/MATLAB/MatlabTools
    git pull

To make this folder automatically on your Matlab path, add the following line
to `startup.m` in your Matlab folder (create the file if it does not exist)

    addpath(fullfile(fileparts(userpath),'MATLAB','MatlabTools'));

You can also clone the repo using Git for Windows, but the above instructions
for `startup.m` may be different depending on where you save the files.

Classes
--------------------------

### @DimVar
The DimVar class (shorthand for Dimensioned Variable) lets you use quantities with units in Matlab with minimal tedious unit conversion. An example use to calculate heat conduction is:

    k = DimVar(2,'BTU-in/hr-ft^2-F');
    A = DimVar(1,'cm2');
    L = DimVar(1,'in');
    DT = DimVar(300,'K') - DimVar(0,'F');
    Q = k*A*DT/L

will show

    0.05068 [kg-m^2/s^3]
    
In this example, the units from the individual components are combined and the resulting units on Q are in power (Watts, all derived quantities will be in SI units). The class also checks unit compatibility during addition, subtraction, comparison, and other math operations. For example, the following command would generate an error since `k` and `L` have different units:

    x = k + L;
    
However, these commands are valid:

    x = L + sqrt(A);
    V = L*A;
    y = exp(-x/L);
    z = 10*A;
    
If you want to do a unit conversion, for example to convert Q from
the example above into BTU/hr, you can do

    Qbtu = Q.Convert('BTU/hr');
    
and Qbtu will be a dimensionless number whose magnitude is now in
BTU/hr. If you attempt to convert Q to meters, it will generate an
error.

You can combine this class with the features of the `@UC` 
class below as well. For example:

    k = DimVar(UC(16,2),'W/m-K');
    L = DimVar(UC(5,1),'mm');
    A = DimVar(UC(10,1),'cm^2');
    DT = DimVar(500,'R') - DimVar(200,'K');

    Q = k*A/L*DT;
    fprintf('Q = %s\n',num2str(Q,4));

will print out

    Q = 248.9 ± 63.76 [kg-m^2/s^3]
    
which has not only propogated the units, but also calculated the 
resulting uncertainty in Q. For more examples, look in `DimVarDemo.m`.

### @UC
The UC class is for manipulating and tracking uncertainty through operator
overloading of basic Matlab scalars and arrays. For usage examples, see
`UCDemo.m`.

You can assign names to UC objects `z = UC(15, 10, 'z')` and then their
contribution to derived uncertainties will be tracked automatically.

If you plot a UC object, it plots the values with both X and Y error
bars if the error is nonzero. To plot only the values of an array of 
UC objects, just use brackets to extract the values as arrays 
(`plot([x.Value],[y.Value])`)

This is a continual work in progress, so if you encounter bugs or things are
not working the way you expect, let me know.

### @Fluid
The Fluid class downloads gas properties from the online NIST database to
allow lookup with temperature and pressure inputs. See `FluidDemo.m` for
usage examples.


Functions
-------------------------

### GetEvenSpacing.m

If you have densely spaced data points, sometimes it is useful to down-sample
the data for plotting markers that are visible. If your data is not evenly
spaced, or is plotted on a log scale, this can become more difficult.

This function gets evenly spaced down-sampled points with the option of
specifying log or linear plotting scales. For example:

    r = GetEvenSpacing(x, y, 50);
    plot(x, y, '-k');
    hold on;
    plot(x(r), y(r), 'sk','MarkerFaceColor','w');

or

    r = GetEvenSpacing(x, y, 50, 'linear', 'log');
    semilogy(x, y, '-k');
    hold on;
    semilogy(x(r), y(r), 'sk','MarkerFaceColor','w');
    
### errorbars_xy.m

This can be used to plot data with both X and Y error bars (which Matlab does
not currently support).

Demo Scripts
------------------------

### FluidDemo.m

Usage examples for the Fluid class.

### GraphDemo.m

General Matlab tutorial on making graphs.

### UCDemo.m

Usage examples for the UC class.

### DimVarDemo.m

Usage examples for the DimVar class.