#!/usr/bin/sh

mkdir -p ./build
odin build engine -out=./build/coffeebean -collection:libs="./libs" -debug -show-timings $@
