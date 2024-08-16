% DXFtool example 1: Showing off possibilities

clc; close all;

% read file and plot
dxf = DXFtool("examples/example2_polylines.dxf");

% list the imported entities
dxf.list;
