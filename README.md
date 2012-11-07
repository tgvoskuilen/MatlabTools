Matlab Tools
============

My custom matlab scripts and classes. To clone this repository into your
Matlab folder (assuming it is at `~/Personal/MATLAB`), enter the following
commands at a UNIX shell (check that you have `git` installed first by typing
`which git`):

    cd ~/Personal/MATLAB
    git clone git@github.com:tgvoskuilen/MatlabTools.git
    
To update your versions of the code if you have already cloned the repository:

    cd ~/Personal/MATLAB/MatlabTools
    git pull



Classes
--------------------------

### @UC
The UC class is for manipulating and tracking uncertainty through operator
overloading of basic Matlab scalars and arrays. For usage examples, see
UCDemo.m.

You can assign names to UC objects `z = UC(15, 10, 'z')` and then their
contribution to derived uncertainties will be tracked automatically.

If you plot a UC object, it uses errorbars_xy to plot the values with error
bars. To plot only the values of an array of UC objects, just use brackets
to extract the values as arrays (`plot([x.Value],[y.Value])`)

### @Fluid
The Fluid class downloads gas properties from the online NIST database to
allow lookup with temperature and pressure inputs. See FluidDemo.m for
usage examples.


Functions
-------------------------

### GetEvenSpacing

If you have densely spaced data points, sometimes it is useful to down-sample
the data for plotting markers that are visible. If your data is not evenly
spaced, or is plotted on a log scale, this can become more difficult.

This function gets evenly spaced down-sampled points with the option of
specifying log or linear plotting scales.

### errorbars_xy

This can be used to plot data with both X and Y error bars (which Matlab does
not currently support).

Demos
------------------------

### FluidDemo

Usage examples for the Fluid class.

### GraphDemo

General Matlab tutorial on making graphs.

### UCDemo

Usage examples for the UC class.
