# Godot-WFC
 Hello, this is my implementation of <a href="https://github.com/mxgmn/WaveFunctionCollapse">WFC algorithm</a> with gui for making tile rules and 3 generators.
 
 
 
 
 <b>Generators</b> - demo in editor 3D view
 
 # RuledLinearGridMap
  Uses only x_plus, y_plus and z_plus fields and checks in linear order on each Z field on each X row of current Y height.

 # RuledRandomVerticalGridMap
  Picks tiles to check randomly for each Y Height
 
 # FullyRuledGridMap
  This generator does not limit max height, but you can choose. Can it go <b>DOWN</b> and can it go <b>UP</b>. Additionaly it checks for cell with lowest possible solutions for that cell. (As in <a href="https://github.com/mxgmn/WaveFunctionCollapse">WFC algorithm</a>)
