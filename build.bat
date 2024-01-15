@echo off
if not exist .\build md .\build
odin build engine -out=.\build\coffeebean.exe -build-mode:exe -collection:libs=".\libs" -debug -show-timings
