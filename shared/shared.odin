package shared

import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"

EntityFlagsEnum :: enum u32
{
	VALID,
	RENDERABLE,
	PHYSICS,
	PLAYER,
}

EntityFlagsSet :: bit_set[EntityFlagsEnum; u32]

Entity :: struct
{
	flags: EntityFlagsSet,
	name: string,
	position: glm.vec3,
	rotation: glm.vec3,
	velocity: glm.vec3,

	model: string,

	update: proc(^Entity),
}

EngineInterface :: struct
{
	entity_create : proc() -> ^Entity,
	load_model_m3d : proc(path: string) -> bool,
	key_down : proc(sc: SDL.Scancode) -> bool,
	key_pressed : proc(sc: SDL.Scancode) -> bool,

	delta_time : ^f32,
	camera: ^Camera,
}

Camera :: struct
{
	position: glm.vec3,
	rotation: glm.vec3,
	target: glm.vec3,
	up: glm.vec3,
	right: glm.vec3,
	forward: glm.vec3,
}


