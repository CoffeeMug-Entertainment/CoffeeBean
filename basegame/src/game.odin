package basegame

import "../../shared"
import glm "core:math/linalg/glsl"
import "core:fmt"
import "core:strings"

ei : shared.EngineInterface

@(export)
game_init :: proc(engine_interface: shared.EngineInterface)
{

	fmt.println("Hello, from game")

	ei = engine_interface

	world_create()
	player_create()
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

player_create :: proc()
{
	player := ei.entity_create()
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