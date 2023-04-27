# CoffeeBean 2 - Percolator

## What is CoffeeBean?

CoffeeBean is a game engine, developed as a hobby and will be used to make 3D games, once it's more or less feature complete.

### Why is there a 2 in the name?

Because this is the second version of the engine bearing that name. [CoffeeBean 1 - Jezva can be found here.](https://gitlab.com/coffeemug-ent/cbe-jezva) After a lot of headaches caused by rewriting the engine, I realised it would be simpler and faster to just begin anew.

## Features

* OpenGL Renderer
* JSON Scene format

### Unfinished features

* Vulkan Renderer
* PBR Rendering
* Baked lighting
* AngelScript Scripting

## How to build?

If you're familiar with CMake, you know what to do.

### Windows - Visual Studio
1. Use CMakeGUI to create project files for the version of VS you are using
2. Load the project files in VS
3. Build 

### Windows - MinGW
Check `Linux` below, the process should be identical

### Linux
1. Create a `build` directory inside this directory.
2. Run `cd build`
3. Run `cmake ..`
4. Depending on your CMake configuration, you either need to run `make` or `ninja`

### MacOS
Unfortunately, I do not own a MacOS device at the moment, so CoffeeBean is not officialy supported on MacOS. If you wish to help out, PRs are very welcome.

## Dependencies

All dependencies, with their respective licenses, should be available in `engine/thirdparty`.