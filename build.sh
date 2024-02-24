#!/usr/bin/sh

mkdir -p ./build

echo "Building Engine"
odin build engine -out=./build/coffeebean -collection:libs="./libs" -debug -show-timings $@
