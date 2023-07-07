# Godot-WFC
 Hello, this is my implementation of <a href="https://github.com/mxgmn/WaveFunctionCollapse">WFC algorithm</a>.

 All is fitted in 1 node.

 # Quick Guide
 1. Disable Generation Lock.
 2. Define meshes in mesh lib data.
 3. Press Generate Mesh Lib.
 4. Paint rules, hwo tiles can connect.
 5. Press Generate Rules.
 6. Define Map Generation Settings.
 7. Press Generate Map.

exported vars Running, Time and Remaining cells shows is generator working.

# Troubleshooting
if generation wails try stopping generation by unchecking running(only if conflict repair is active)

after that check error out 
- value 0 is tile position
- value 1 are all possible tiles from each side that can be placed at that spot
- value 2 shows which arrays are being used for that cell
