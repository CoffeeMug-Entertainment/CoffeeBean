package basegame

import "../../shared"
import glm "core:math/linalg/glsl"
import "core:fmt"
import "core:strings"

ei : shared.EngineInterface

@(export)
game_init :: proc(engine_interface: shared.EngineInterface)
{
	ei = engine_interface

	world_create()
	player_create()
}

GAME_FONT :: "./basegame/fonts/FontCodeMonospace.png"

@(export)
game_ui :: proc()
{
	font_size :f32: 6
	text_scale :f32: 2

	text := "DreamRealms - SOME ASSETS ARE PLACEHOLDER AND WILL NOT BE IN THE FINAL GAME"
	x_start : f32 = cast(f32)(1280 / 2) - (cast(f32)len(text) * (text_scale * font_size) / 2)
	ei.screen_print(GAME_FONT, glm.vec2{x_start, 2}, 2, text)

	ei.screen_tprintf(GAME_FONT, glm.vec2{0, 720 - text_scale * font_size - 2}, 2, "v0.1.0")

	//WHY IS tprintf version bugged?
	//ei.screen_tprintf(GAME_FONT,  glm.vec2{0, text_scale}, 2, "X: %f\nY: %f\nZ: %f", player.position.x, player.position.y, player.position.z)
	ei.screen_print(GAME_FONT, glm.vec2{0, text_scale}, 2, fmt.tprintf("X: %f\nY: %f\nZ: %f", player.position.x, player.position.y, player.position.z))
}

WORLD_MODEL :: "./basegame/maps/test.m3d"

world_create :: proc()
{
	ei.load_model_m3d(WORLD_MODEL)

	world := ei.entity_create()
	world.model = WORLD_MODEL
	world.name = "World"
	world.flags |= {.RENDERABLE}
	if strings.contains(WORLD_MODEL, ".m3d") do world.rotation.x = -90 //TEMP hackery, lol
	//world.rotation.x = -90
}

player : ^shared.Entity
player_create :: proc()
{
	player = ei.entity_create()
	player.name = "Player"
	player.flags |= {.PLAYER}
	player.update = player_update
	player.position = glm.vec3{0, 56, 0}
}

player_update :: proc(player: ^shared.Entity)
{
	SPEED :: 320.0
	move_dir: glm.vec3

	delta_speed := SPEED * ei.delta_time^
	if ei.key_down(.LSHIFT) 
	{
		delta_speed *= 10	
	}

	if ei.key_down(.A)
	{
		move_dir -= ei.camera.right * delta_speed
	}
	if ei.key_down(.D)
	{
		move_dir += ei.camera.right * delta_speed
	}

	if ei.key_down(.W)
	{
		move_dir += ei.camera.forward * delta_speed
	}
	if ei.key_down(.S)
	{
		move_dir -= ei.camera.forward * delta_speed
	}
	
	if ei.key_down(.SPACE)
	{
		move_dir += ei.camera.up * delta_speed
	}
	if ei.key_down(.C)
	{
		move_dir -= ei.camera.up * delta_speed
	}

	player.position += move_dir

	ei.camera.position = player.position
	//g_camera.rotation = player.rotation
}