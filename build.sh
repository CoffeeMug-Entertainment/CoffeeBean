#!/usr/bin/sh

mkdir -p ./build

echo "Building Engine"
odin build engine -out=./build/coffeebean -collection:libs="./libs" -debug -show-timings $@

#echo "Building Basegame"
#odin build basegame/src -out=./basegame/game -build-mode:dll -debug -show-timings $@

# Thanks @ReformedJoe for the name
echo "Building Map Compiler"
odin build map_compiler -out=./build/percolator -collection:libs="./libs" -debug -show-timings $@