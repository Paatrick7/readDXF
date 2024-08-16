[toc]

# readDXF说明文档

## 1. 使用说明
**本函数是基于Matlab的FileExchange的库函数**
[DXFtool](https://www.mathworks.com/matlabcentral/fileexchange/66632-dxftool)**进行修改的，对于支持的实体类型进行了补充和完善，可以点击链接查看。** 

### 1.1 使用方法

将.m文件放在同一目录下，直接调用DXFtool即可，如下example3.m当中测试ex3.dxf文件的读取：
```matlab
% DXFtool example 3: CAD drawing from SolidWorks

clc; close all;

% read file and plot
dxf = DXFtool('examples/ex3.dxf');

% list the imported entities
dxf.list;

```

**更改函数转换的比例：**

在readDXF函数中找到开头的计算scale部分
```matlab
scale=getScaleFactor(units,'None')
```
将'None'改作目标（当前图纸）比例，默认'None'即比例为1，具体转化比例可以参照getScaleFactor函数，下面是函数的定位
```matlab
function entities = read_dxf(filename)
    fid = fopen(filename); 
    if fid == -1
        error("无法打开文件");
    end
    %公制或者英制单位
    units = 'Unknown';
    flag=false;
    while ~feof(fid)
        line = fgetl(fid);
        if contains(line, '$INSUNITS')
            fgetl(fid); % 忽略70
            unitsValue = str2double(fgetl(fid));
            flag=true;
            break;
        end
    end
    
    % 转换单位数值为字符串
    if flag
        switch unitsValue
            case 0, units = 'None';
            case 1, units = 'Inches';
            case 2, units = 'Feet';
            case 3, units = 'Miles';
            case 4, units = 'Millimeters';
            case 5, units = 'Centimeters';
            case 6, units = 'Meters';
            case 7, units = 'Kilometers';
            case 8, units = 'Microinches';
            case 9, units = 'Mils';
            case 10, units = 'Microns';
            case 11, units = 'Decimeters';
            otherwise, units = 'Unknown';
        end
    end
    disp(['DXF文件单位为: ', units]);
    %在这里更改scale转化
    scale = getScaleFactor(units,'None');
    fclose(fid);
%%
%略
end
```
**本函数可以解析的实体类型：**

主要是二维平面下的类型，三维暂不支持

```matlab
FEATURES:
- supports: LINE, POINT, ARC, CIRCLE, ELLIPSE, LWPOLYLINE,POLYLINE
- colored entities (line and hatch color)
- respects ordering of objects (back to front)
- supports bulges, open/closed polygons
- line dashing

```
### 1.2 注意事项

**注意：**

**1.本函数面向的AutoCAD版本主要是2004-2006的，较为新的版本的dxf文件很有可能出现报错的可能！**

**2.dxf文件需要严格按照文件格式编写，不得出现空行等不标准的格式情况，否则会报错。**

**3.因为dxf的文件格式的特性的缘故，需要逐行去解析，所以运行时间往往会以秒为单位（当实体个数超过5000个的时候很容易发生）**

## 2. 函数解析
### 2.1 dxf结构体解析
dxf存储了文件路径、实体类、实体类大小等

```matlab
properties
    filename;       % path/filename of DXF file
    entities;       % struct array of entities
    ne;             % number of entities
    divisions = 50; % points along nonlinear entities (circles, arcs, bulges, ellipses)
end
```
entities同样也是一个结构体，存储着不同类型实体的各种信息如下的POLYLINE：
![屏幕截图%202024-08-15%20140924](img/屏幕截图%202024-08-15%20140924.png)

对于整个函数的输入输出结构如下
```matlab
INPUT:    filename of dxf file as a string (may also include path)

OUTPUT:   [optional] dxf object. Each entity is stored in a struct
          in dxf.entites(i), where i is the entity number,
          containing the following fields:
          .name:      entity type name (string), code 0
          .layer:     Layer name (string), code 8
          .linetype:  Line dashing type (string), code 6
          .color:     Line color (int), code 62
          .closed:    polygon status: open/closed, code 70
          .point:     Xp, Yp
          .poly:      vertices X,Y array [n_verts,2]
          .arc:       Xc, Yc, R, begin angle, end angle
          .circle:    Xc, Yc, R
          .ellipse:   Xc, Yc, Xe, Ye, ratio, begin angle, end angle
          .line:      X1, Y1, X2, Y2
          .hatch:     color data for closed polygons
          .handle:    Matlab graphics handle to plotted entity
```
### 2.2 readDXF
该函数用于读取dxf文件，并提取实体信息存储到dxf.entities当中，按照关键词进行提取，如遇到POLYLINE结构的（含有VERTEX结构）则会忽略中间部分的VERTEX和SEQUEND等关键词则会跳过，不会记录在entities当中。

### 2.3 plot
本函数是用于绘制读取到的entities，根据实体类型的不同调用不同的绘制函数来进行绘制。

如解析example4_primitives.dxf文件：

![屏幕截图%202024-08-15%20142942](img/屏幕截图%202024-08-15%20142942.png)

### 2.4 dxf.list
本函数是用于列出entities的内容，按照一定的排列输出到命令行上，帮助用户以查看信息。

如解析example4_primitives.dxf文件：

![屏幕截图%202024-08-15%20143056](img/屏幕截图%202024-08-15%20143056.png)


## 3.局限性
### 3.1 支持的实体类型有限
当前代码只支持部分实体类型，如 LINE, POINT, ARC, CIRCLE, ELLIPSE, LWPOLYLINE 和 SPLINE。这意味着如果 DXF 文件中包含其他类型的实体（如 DIMENSION, TEXT, 3D FACE 等），该工具无法解析或绘制这些实体。

### 3.2 对 SPLINE 的处理简化
代码中对 SPLINE 实体的处理是通过将其简化为分段的线段（piecewise linear），这对于复杂的样条曲线可能无法精确表示原始的几何形状。

### 3.3 不支持三维实体
该工具仅处理二维的 DXF 实体，对于三维的实体（如 3D FACE, POLYFACE MESH 等）无法进行解析或绘制。

### 3.4 多段线的处理缺乏复杂性
代码仅简单地处理 LWPOLYLINE，并将其分为顶点和曲率部分，没有更高级的处理，如多段线中的复杂几何属性的处理（如宽度、样式等）。

### 3.5 缺乏对复杂属性的支持
对于某些实体的特定属性（如 LINEWEIGHT、THICKNESS 等），当前代码没有实现处理。这可能导致在某些情况下，绘制的图形与实际情况有出入。

### 3.6 对 HATCH 的处理不完善
虽然 HATCH 实体会被解析，但代码中只是将其用于填充颜色，没有实现对复杂的填充图案的支持。

### 3.7 颜色映射问题
颜色映射的实现比较简单，虽然可以处理大部分情况，但对复杂的颜色设置（如 BYBLOCK、BYLAYER 等）可能处理不准确。

### 3.8 实体解析的鲁棒性不足：

代码中对实体解析的部分假设了某些字段必然存在（如 eStrings{eCodes==8}），这在处理某些特殊或不标准的 DXF 文件时可能会导致错误或崩溃。

## 4. 测试函数说明
### 4.1 测试用例

测试用例均在examples文件夹下，对应了多种实体类型，均通过了测试。

### 4.2 测试函数

提供了三个测试函数，分别是example1.m，example2.m和example3.m，三个测试函数对应三个测试用例，前两个针对一般的绘制情况，第三个是在本函数的基础上对解析的实体的进一步处理。

**想要测试其他dxf文件，可以在example1.m的基础上更改文件的相对路径即可。**

### 4.3 测试结果

经测试，Point，POLYLINE，LWPOLYLINE，以及多线段的HATCH填充，CIRCLE，ARC，ELLIPSE，TEXT均可以解析并存储到entities当中，绘制能绘制除了POINT，TEXT的实体类型。

example2_polylines.dxf

![屏幕截图%202024-08-15%20152130](img/屏幕截图%202024-08-15%20152130.png)

example3_polymesh.dxf

![屏幕截图%202024-08-15%20152139](img/屏幕截图%202024-08-15%20152139.png)

ex1.dxf

![屏幕截图%202024-08-15%20152147](img/屏幕截图%202024-08-15%20152147.png)

ex2.dxf
![屏幕截图%202024-08-15%20152551](img/屏幕截图%202024-08-15%20152551.png)

ex3.dxf

![屏幕截图%202024-08-15%20152346](img/屏幕截图%202024-08-15%20152346.png)