% DXFtool example 3: CAD drawing from SolidWorks

clc; close all;

% read file and plot
dxf = DXFtool('examples/ex3.dxf');

% list the imported entities
dxf.list;
