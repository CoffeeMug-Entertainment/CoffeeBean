@echo off
if not exist .\build md .\build
echo "Building Engine"
odin build engine -out=.\build\coffeebean.exe -build-mode:exe -collection:libs=".\libs" -debug -show-timings

echo "Building Basegame"
odin build basegame/src -out=.\basegame\game -build-mode:dll -debug -show-timings

:: Thanks @ReformedJoe for the name
echo "Building Map Compiler"
odin build map_compiler -out=.\build\percolator -collection:libs=".\libs" -debug -show-timings