# gorilla locomotion & marching cubes terrain
## for lovr 0.17

i tried to organize this enough that the locomotion and the terrain can be dropped into other projects, but i only got partway. feel free to ask questions about it in the lovr community! i probably won't be updating it anytime soon, i've been focusing on other projects.

the structure is:
- `uses-player-library.lua`: run lovr on this file. it uses the other libraries, and does the drawing
- `player-library.lua` handles game-specific player logic, like controls and bird flapping
- `biped.lua` handles gorilla locomotion math. theoretically, it shouldn't need to be customized to fit a particular game, and it shouldn't need to be customized to be used by enemy AI. there might be bugs or unimplemented features though.
- `cubes-library.lua`: marching cubes library. it also generates baked ambient occlusion, stored in the vertices
- `marching.lua`: data needed for the marching cubes library
- `jprof.lua`: profiling tool, https://github.com/KelseyHigham/jprof-lovr
- `MessagePack.lua`: needed for jprof