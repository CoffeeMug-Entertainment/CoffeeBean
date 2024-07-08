#!/usr/bin/sh

mkdir -p ./build

echo "Building Engine"
odin build engine -out=./build/coffeebean -collection:libs="./libs" -debug -show-timings $@

# Thanks @ReformedJoe for the name
echo "Building Map Compiler"
odin build map_compiler -out=./build/percolator -collection:libs="./libs" -debug -show-timings $@