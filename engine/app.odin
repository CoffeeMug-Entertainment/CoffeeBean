package CBE

import "libs:mdf"

import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

import "core:log"
import "core:strings"
import "core:strconv"

TARGET_FPS :: 60
TARGET_FRAMETIME :f32: 1000/TARGET_FPS

App :: struct
{
	window : ^SDL.Window,
	gl_context : SDL.GLContext,
	running : bool,
	delta_time: f32,

	//Screen Framebuffer
	screen_framebuffer: u32,
	screen_colorbuffer: u32,
	screen_renderbuffer: u32,
	screen_shaderprogram: u32,
	screen_shaderuniforms: gl.Uniforms,
	screen_vtx_vbo: u32,
	screen_uv_vbo: u32,
	screen_vao: u32,
	screen_ebo: u32,

	//Assets
	models: map[string]Model,
	textures: map[string]Texture,
	fonts: map[string]Font,

	//Input
	keyboard_state: []u8,
	last_keyboard_state: []u8,

	//Entities
	entities: [1024]Entity,
	entity_count: u32,
}

g_program : u32
g_uniforms: gl.Uniforms

key_down :: proc(sc: SDL.Scancode) -> bool
{
	return g_app.keyboard_state[sc] > 0
}

key_pressed :: proc(sc: SDL.Scancode) -> bool
{
	return g_app.keyboard_state[sc] > 0 && g_app.last_keyboard_state[sc] == 0
}

app_init :: proc() -> bool
{
	// SDL
	sdl_init_error := SDL.Init(SDL.INIT_EVERYTHING)
	if sdl_init_error < 0 do return false

	g_app.window = SDL.CreateWindow("CoffeeBean", 
								SDL.WINDOWPOS_CENTERED, SDL.WINDOWPOS_CENTERED,
								1280, 720,
								SDL.WINDOW_SHOWN | SDL.WINDOW_OPENGL)

	if g_app.window == nil do return false

	//GL
	SDL.GL_SetAttribute(.CONTEXT_PROFILE_MASK,  i32(SDL.GLprofile.CORE))
	SDL.GL_SetAttribute(.CONTEXT_MAJOR_VERSION, 3)
	SDL.GL_SetAttribute(.CONTEXT_MINOR_VERSION, 0)
	g_app.gl_context = SDL.GL_CreateContext(g_app.window)
	gl.load_up_to(3, 0, SDL.gl_set_proc_address)

	program, ok := gl.load_shaders_source(VERTEX_DEFAULT_SRC, FRAGMENT_DEFAULT_SRC)
	if !ok {log.error("GLSL Error: ", gl.get_last_error_message()); return false}

	g_program = program
	g_uniforms = gl.get_uniforms_from_program(program)

	gl.Enable(gl.DEPTH_TEST)

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)  

	/*
	gl.Enable(gl.CULL_FACE)
	gl.CullFace(gl.FRONT)
	*/

	//Framebuffer
	gl.GenFramebuffers(1, &g_app.screen_framebuffer)
	gl.BindFramebuffer(gl.FRAMEBUFFER, g_app.screen_framebuffer)

	gl.GenTextures(1, &g_app.screen_colorbuffer)
	gl.BindTexture(gl.TEXTURE_2D, g_app.screen_colorbuffer)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGB, 1280, 720, 0, gl.RGB, gl.UNSIGNED_BYTE, nil)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
	gl.FramebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, g_app.screen_colorbuffer, 0)

	gl.GenRenderbuffers(1, &g_app.screen_renderbuffer)
	gl.BindRenderbuffer(gl.RENDERBUFFER, g_app.screen_renderbuffer)
	gl.RenderbufferStorage(gl.RENDERBUFFER, gl.DEPTH24_STENCIL8, 1280, 720)

	gl.FramebufferRenderbuffer(gl.FRAMEBUFFER, gl.DEPTH_STENCIL_ATTACHMENT, gl.RENDERBUFFER, g_app.screen_renderbuffer)

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)

	gl.GenVertexArrays(1, &g_app.screen_vao)
	gl.BindVertexArray(g_app.screen_vao)

	gl.GenBuffers(1, &g_app.screen_vtx_vbo)

	gl.BindBuffer(gl.ARRAY_BUFFER, g_app.screen_vtx_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(SCREEN_VTX) * size_of(SCREEN_VTX[0]), raw_data(SCREEN_VTX), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

	gl.GenBuffers(1, &g_app.screen_uv_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, g_app.screen_uv_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, len(SCREEN_UV) * size_of(SCREEN_UV[0]), raw_data(SCREEN_UV), gl.STATIC_DRAW)
	gl.EnableVertexAttribArray(1)
	gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(glm.vec2), 0)

	gl.GenBuffers(1, &g_app.screen_ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, g_app.screen_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(SCREEN_EBO) * size_of(SCREEN_EBO[0]), raw_data(SCREEN_EBO), gl.STATIC_DRAW)

	program, ok = gl.load_shaders_source(SCREEN_VERTEX_DEFAULT_SRC, SCREEN_FRAGMENT_DEFAULT_SRC)
	if !ok {log.error("GLSL Error: ", gl.get_last_error_message()); return false}

	g_app.screen_shaderprogram = program
	g_app.screen_shaderuniforms = gl.get_uniforms_from_program(program)

	SDL.GL_SetSwapInterval(1) //Vsync

	//stbi.set_flip_vertically_on_load_thread(true)

	g_app.keyboard_state = SDL.GetKeyboardStateAsSlice()

	//Camera
	g_camera.position = glm.vec3{0, 0, 1}
	g_camera.position = glm.vec3{0, 0, 1}
	g_camera.target = glm.vec3{0, 0, 0}
	g_camera.up = glm.vec3{0, 1, 0}


	//Entities
	g_app.entity_count = 0

	for i := 0; i < 1024; i += 1
	{
		en := &g_app.entities[i]
		en.flags = {}
		en.position = glm.vec3{0, 0, 0}
		en.velocity = glm.vec3{0, 0, 0}
		en.update = nil
	}

	world_create()
	player_create()

	g_app.running = true

	return true
}

app_shutdown :: proc()
{
	//QUESTION(fhomolka): Do we even care about freeing some of these in release mode?
	gl.destroy_uniforms(g_app.screen_shaderuniforms)
	gl.destroy_uniforms(g_uniforms)

	for _, model in g_app.models
	{
		for mesh in model.meshes
		{
			delete(mesh.name)
			delete(mesh.vertices)
			delete(mesh.uvs)
			for submesh in mesh.submeshes
			{
				delete(submesh.indices)
				delete(submesh.material)
			}
			delete(mesh.submeshes)
		}
		delete(model.meshes)
	}	
	delete(g_app.models)


	for _, texture in g_app.textures
	{
		//BUG(fhomolka) Apparently it's not there?
		//These are not explicitly freed anywhere, but it causes a segfault when attempting to free them
		//Tracking allocator isn't complaining
		//free(texture.data)
	}
	delete(g_app.textures)

	delete(g_app.keyboard_state)
	delete(g_app.last_keyboard_state)

	SDL.GL_DeleteContext(g_app.gl_context)
	SDL.DestroyWindow(g_app.window)
	SDL.Quit()
}

app_process_events :: proc()
{
	event: SDL.Event

	for SDL.PollEvent(&event)
	{
		#partial switch event.type 
		{
			case .QUIT:
			{
				g_app.running = false
			}
			//Pumping events for the KeyboardState
			case .KEYUP:{}
			case .KEYDOWN:{}
			case .MOUSEMOTION:
			{
				mousemovement := glm.vec2{cast(f32)event.motion.xrel, cast(f32)event.motion.yrel}
				camera_rotate(mousemovement * g_app.delta_time * 8)
			}
		}
	}
}

mouse_captured :SDL.bool= false

app_update :: proc()
{
	//TEMP
	if key_down(.ESCAPE)
	{
		g_app.running = false
	}

	for i := 0; i < 1024; i += 1
	{
		en := &g_app.entities[i]

		if .VALID not_in en.flags do continue

		if en.update != nil do en.update(en)
	}

	//TEMP
	{
		if key_pressed(.F1)
		{
			mouse_captured = !mouse_captured
			SDL.SetRelativeMouseMode(mouse_captured)
		}
	}
}

app_render :: proc()
{
	view := glm.mat4LookAt(g_camera.position, g_camera.position + g_camera.forward, g_camera.up)
	proj := glm.mat4Perspective(1, 16.0/9.0, 0.05, 2048.0)

	gl.BindFramebuffer(gl.FRAMEBUFFER, g_app.screen_framebuffer)
	gl.Enable(gl.DEPTH_TEST)

	gl.Viewport(0, 0, 1280, 720)
	gl.ClearColor(0.21, 0.21, 0.21, 1.0)
	gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)

	gl.UseProgram(g_program)
	for i := 0; i < 1024; i += 1
	{
		en := &g_app.entities[i]
		if .VALID not_in en.flags do continue
		if .RENDERABLE not_in en.flags do continue

		entity_render(en, view, proj)
	}

	gl.BindFramebuffer(gl.FRAMEBUFFER, 0)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.UseProgram(g_app.screen_shaderprogram)
	gl.BindVertexArray(g_app.screen_vao)
	gl.Disable(gl.DEPTH_TEST)
	gl.BindTexture(gl.TEXTURE_2D, g_app.screen_colorbuffer)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, g_app.screen_ebo)
	gl.DrawElements(gl.TRIANGLES, i32(len(SCREEN_EBO)), gl.UNSIGNED_SHORT, nil)


	//TODO: Move to game code
	{
		font_size :f32: 6
		text_scale :f32: 2

		text := "DreamRealms - SOME ASSETS ARE PLACEHOLDER AND WILL NOT BE IN THE FINAL GAME"
		x_start : f32 = cast(f32)(1280 / 2) - (cast(f32)len(text) * (text_scale * font_size) / 2)
		easy_print(glm.vec3{cast(f32)x_start, 1 + text_scale, text_scale}, text)

		easy_print(glm.vec3{0, 720 - text_scale * font_size - 2, text_scale}, "v0.1.0")

		player := &g_app.entities[1]
		easy_print(glm.vec3{0, text_scale, text_scale}, fmt.tprintf("%v\n%v\n%v", player.position.x, player.position.y, player.position.z))
	}
	
	SDL.GL_SwapWindow(g_app.window)
}

g_app : App

aspect_ratio :: 16.0/9.0

VERTEX_DEFAULT_SRC :: #load("./shaders/default_vertex.glsl", string)
FRAGMENT_DEFAULT_SRC :: #load("./shaders/default_fragment.glsl", string)
SCREEN_VERTEX_DEFAULT_SRC :: #load("./shaders/default_screen_vertex.glsl", string)
SCREEN_FRAGMENT_DEFAULT_SRC :: #load("./shaders/default_screen_fragment.glsl", string)

SCREEN_VTX :: []glm.vec3 {
	{-1.0, -1.0, 0.0},
	{1.0, -1.0, 0.0},
	{1.0, 1.0, 0.0},
	{-1.0, 1.0, 0.0},
}

SCREEN_UV :: []glm.vec2 {
	{0.0, 0.0},
	{1.0, 0.0},
	{1.0, 1.0},
	{0.0, 1.0},
}

SCREEN_EBO :: []u16{
	0, 1, 2,
	0, 2, 3,
}

Submesh :: struct
{
	material: string,
	indices: [dynamic]u16,

	ebo: u32,
}

Mesh :: struct
{
	name: string,
	local_transform: glm.mat4,
	vertices: [dynamic]glm.vec3,
	uvs: [dynamic]glm.vec2,
	submeshes: [dynamic]Submesh,

	vao: u32,
	vertex_vbo: u32,
	uv_vbo: u32,
}

Model :: struct
{
	meshes: [dynamic]Mesh,
}

Texture :: struct
{
	width: i32,
	height: i32,
	npp: i32,
	data: [^]byte,

	ID: u32,
}

model_render :: proc(model: ^Model, transform_matrix: glm.mat4, projection_matrix: glm.mat4, view_matrix: glm.mat4)
{
	gl.UseProgram(g_program)
	
	for mesh in model.meshes
	{
		gl.BindVertexArray(mesh.vao)

		u_transform := projection_matrix * view_matrix * (/*mesh.local_transform + */ transform_matrix)
		gl.UniformMatrix4fv(g_uniforms["u_transform"].location, 1, false, &u_transform[0, 0])

		for submesh, s in mesh.submeshes
		{
			smesh_ref := mesh.submeshes[s]

			gl.ActiveTexture(gl.TEXTURE0)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			gl.BindTexture(gl.TEXTURE_2D, g_app.textures[smesh_ref.material].ID)

			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, submesh.ebo)
			gl.DrawElements(gl.TRIANGLES, i32(len(submesh.indices)), gl.UNSIGNED_SHORT, nil)
		}
	}
}

load_model_m3d :: proc(path: string) -> bool
{
	doc, doc_ok := mdf.load_from_file(path)

	if doc_ok != .NONE do return false

	if doc.properties[0].(mdf.Chunk).name != "Mars3DScene"
	{
		log.error("%s is not a M3D model!\n", path)
		return false
	}

	doc_objects := doc.properties[0].(mdf.Chunk).properties["Objects"].(mdf.Array)

	model: Model

	for p in doc_objects.properties
	{
		switch e in p 
		{
			case mdf.Chunk:
			mesh: Mesh

			mesh.name = strings.clone(e.properties["Name"].(mdf.Value).val)
			
			//Local Transform
			{
				transform_str := e.properties["LocalTransform"].(mdf.Value).val
				transform_val_arr := strings.split(transform_str, " ")
				defer delete(transform_val_arr)

				for y := 0; y < 4; y += 1
				{
					for x := 0; x < 4; x += 1
					{
						idx := x + y * 4
						temp_val, ok := strconv.parse_f32(transform_val_arr[idx])
						mesh.local_transform[x, y] = temp_val
					}
				}
			}
			
			//Vertices
			{
				vtx_ar := e.properties["Vertices"].(mdf.Array)

				for vtx_val in vtx_ar.properties
				{
					vtx_str_arr := strings.split(vtx_val.(mdf.Value).val, " ")
					defer delete(vtx_str_arr)
					vec: glm.vec3
					for v, i in vtx_str_arr
					{
						temp_val, ok := strconv.parse_f32(v)
						vec[i] = temp_val
					}
					append(&mesh.vertices, vec)
				}
			}

			// UVs
			{
				uv_ar := e.properties["UVs"].(mdf.Array)
				for uv_val in uv_ar.properties
				{
					uv_str_arr := strings.split(uv_val.(mdf.Value).val, " ")
					defer delete(uv_str_arr)
					uv: glm.vec2
					for u, i in uv_str_arr
					{
						temp_val, ok := strconv.parse_f32(u)
						uv[i] = temp_val
					}
					append(&mesh.uvs, uv)
				}
			}
			// Submeshes
			{
				submesh_ar := e.properties["Submeshes"].(mdf.Array)
				for s in submesh_ar.properties
				{
					c := s.(mdf.Chunk)
					submesh: Submesh

					submesh.material = strings.clone(c.properties["Material"].(mdf.Value).val)

					indices_ar := c.properties["Indices"].(mdf.Array)
					for idx, i in indices_ar.properties
					{
						temp_val, ok := strconv.parse_uint(idx.(mdf.Value).val)
						append(&submesh.indices, u16(temp_val))
					}

					append(&mesh.submeshes, submesh)
				}
			}

			append(&model.meshes, mesh)
			
			case mdf.Array:
			//fmt.println(e.name)
			case mdf.Value:
			//fmt.println(e.name)
		}
	}

	for m := 0; m < len(model.meshes); m += 1
	{
		mesh := &model.meshes[m]

		gl.GenVertexArrays(1, &mesh.vao)
		gl.BindVertexArray(mesh.vao)

		gl.GenBuffers(1, &mesh.vertex_vbo)
		gl.BindBuffer(gl.ARRAY_BUFFER, mesh.vertex_vbo)
		gl.BufferData(gl.ARRAY_BUFFER, len(mesh.vertices) * size_of(mesh.vertices[0]), raw_data(mesh.vertices), gl.STATIC_DRAW)

		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

		gl.GenBuffers(1, &mesh.uv_vbo)
		gl.BindBuffer(gl.ARRAY_BUFFER, mesh.uv_vbo)
		gl.BufferData(gl.ARRAY_BUFFER, len(mesh.uvs) * size_of(mesh.uvs[0]), raw_data(mesh.uvs), gl.STATIC_DRAW)

		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(1, 2, gl.FLOAT, false, size_of(glm.vec2), 0)

		for i := 0; i < len(mesh.submeshes); i += 1
		{
			smesh := &mesh.submeshes[i]

			load_texture(smesh.material)
			push_image_to_GPU(smesh.material)


			gl.GenBuffers(1, &smesh.ebo)
			gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, smesh.ebo)
			gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(smesh.indices) * size_of(smesh.indices[0]), raw_data(smesh.indices), gl.STATIC_DRAW)
		}
	}

	g_app.models[path] = model

	//QUESTION(fhomolka): Keep the doc in memory, for use for substrings for stuff like materials
	//					  Instead of cloning strings
	mdf.destroy(doc)

	return true
}

load_texture :: proc(path: string)
{
	filepath_cstring := strings.clone_to_cstring(path)
	new_sprite: Texture

	new_sprite.data = stbi.load(filepath_cstring, &new_sprite.width, &new_sprite.height, &new_sprite.npp, 0)


	g_app.textures[path] = new_sprite
	delete(filepath_cstring)
}

push_image_to_GPU :: proc(texture_id: string)
{
	texture := &g_app.textures[texture_id]

	gl.GenTextures(1, &texture.ID)
	gl.BindTexture(gl.TEXTURE_2D, texture.ID)

	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texture.width, texture.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, &texture.data[0])
}

import "vendor:stb/easy_font"

VERTEX_TEXT_SRC :: #load("./shaders/default_text_vertex.glsl", string)
FRAGMENT_TEXT_SRC :: #load("./shaders/default_text_fragment.glsl", string)
g_easy_text_program: u32
g_easy_text_program_uniforms: gl.Uniforms

quad_idx : []u16 = { 0, 1, 2, 
					 0, 2, 3};

quad_ebo: u32

easy_print :: proc(pos: glm.vec3, text: string)
{
	if quad_ebo == 0
	{
		log.info("Creating an easy_text ebo")
		gl.GenBuffers(1, &quad_ebo)
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ebo)
		gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(quad_idx) * size_of(quad_idx[0]), raw_data(quad_idx), gl.STATIC_DRAW)
	}

	if g_easy_text_program == 0
	{
		log.info("Compiling easy_text shader")
		program, ok := gl.load_shaders_source(VERTEX_TEXT_SRC, FRAGMENT_TEXT_SRC)
		if !ok {log.error("GLSL Error: ", gl.get_last_error_message()); return}

		g_easy_text_program = program
		g_easy_text_program_uniforms = gl.get_uniforms_from_program(g_easy_text_program)
	}

	quads: [999]easy_font.Quad = ---
	colour := easy_font.Color{255, 255, 255, 255}
	quad_num := easy_font.print_quad_buffer(pos.x, pos.y, text, colour, quads[:], pos.z)


	gl.UseProgram(g_easy_text_program)
	view := glm.mat4LookAt({0, 0, 1}, {0, 0, 0}, {0, 1, 0})
	u_projection := glm.mat4Ortho3d(0, 1280, 720, 0, 0.5, 1000) * view
	gl.UniformMatrix4fv(g_easy_text_program_uniforms["u_projection"].location, 1, false, &u_projection[0, 0])

	for quad in quads[:quad_num]
	{
		quad_vtx : []glm.vec3 =
		{
			cast(glm.vec3)quad.tl.v,
			cast(glm.vec3)quad.bl.v,
			cast(glm.vec3)quad.br.v,
			cast(glm.vec3)quad.tr.v,
		}

		vertex_vao: u32
		vertex_vbo: u32
		gl.GenVertexArrays(1, &vertex_vao)
		gl.BindVertexArray(vertex_vao)

		gl.GenBuffers(1, &vertex_vbo)
		gl.BindBuffer(gl.ARRAY_BUFFER, vertex_vbo)
		gl.BufferData(gl.ARRAY_BUFFER, len(quad_vtx) * size_of(quad_vtx[0]), raw_data(quad_vtx), gl.STATIC_DRAW)

		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(0, 3, gl.FLOAT, false, size_of(glm.vec3), 0)

		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ebo)
		gl.DrawElements(gl.TRIANGLES, i32(len(quad_idx)), gl.UNSIGNED_SHORT, nil)

		gl.BindBuffer(gl.ARRAY_BUFFER, 0)
		gl.DeleteBuffers(1, &vertex_vbo)

		gl.BindVertexArray(0)
		gl.DeleteVertexArrays(1, &vertex_vao)
	}
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

g_camera: Camera

camera_move :: proc(dir: glm.vec3)
{
	g_camera.position += dir
	g_camera.target += dir

}

CAM_V_LIMIT :: 89.9

camera_rotate :: proc(dir: glm.vec2)
{
	using g_camera
	g_camera.rotation.x -= dir.y
	g_camera.rotation.y += dir.x

	g_camera.rotation.x = clamp(g_camera.rotation.x, -CAM_V_LIMIT, CAM_V_LIMIT)

	forward.x = glm.cos(glm.radians(rotation.y)) * glm.cos(glm.radians(rotation.x))
	forward.y = glm.sin(glm.radians(rotation.x))
	forward.z = glm.sin(glm.radians(rotation.y)) * glm.cos(glm.radians(rotation.x))
	forward = glm.normalize(forward)

	right = glm.normalize(glm.cross(forward, glm.vec3{0, 1, 0}))
	up = glm.normalize(glm.cross(right, forward))
}

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

entity_create :: proc() -> ^Entity
{
	en := &g_app.entities[g_app.entity_count]
	en.flags |= {.VALID}

	g_app.entity_count += 1

	return en
}

entity_render :: proc(en: ^Entity, view_matrix: glm.mat4, proj_matrix: glm.mat4)
{
	transform_matrix := glm.identity(glm.mat4)
	transform_matrix += glm.mat4Translate(en.position)
	transform_matrix *= glm.mat4Rotate(glm.vec3{1, 0, 0}, glm.radians(en.rotation.x))
	transform_matrix *= glm.mat4Rotate(glm.vec3{0, 1, 0}, glm.radians(en.rotation.y))
	transform_matrix *= glm.mat4Rotate(glm.vec3{0, 0, 1}, glm.radians(en.rotation.z))

	model := &g_app.models[en.model]
	model_render(model, transform_matrix, proj_matrix, view_matrix)
	
}

WORLD_MODEL :: "./basegame/models/map.m3d"

world_create :: proc()
{
	load_model_m3d(WORLD_MODEL)

	world := entity_create()
	world.model = WORLD_MODEL
	world.name = "World"
	world.flags |= {.RENDERABLE}
	if world.model == "./basegame/models/map.m3d" do world.rotation.x = 90 //TEMP hackery, lol
}

player_create :: proc()
{
	player := entity_create()
	player.name = "Player"
	player.flags |= {.PLAYER}
	player.update = player_update
	player.position = glm.vec3{0, 56, 0}
}

import "core:fmt"

player_update :: proc(player: ^Entity)
{
	SPEED :: 30.0
	move_dir: glm.vec3

	delta_speed := SPEED * g_app.delta_time
	if key_down(.LSHIFT) 
	{
		delta_speed *= 10	
	}

	if key_down(.A)
	{
		move_dir -= g_camera.right * delta_speed
	}
	if key_down(.D)
	{
		move_dir += g_camera.right * delta_speed
	}

	if key_down(.W)
	{
		move_dir += g_camera.forward * delta_speed
	}
	if key_down(.S)
	{
		move_dir -= g_camera.forward * delta_speed
	}
	
	if key_down(.SPACE)
	{
		move_dir += g_camera.up * delta_speed
	}
	if key_down(.C)
	{
		move_dir -= g_camera.up * delta_speed
	}

	player.position += move_dir

	g_camera.position = player.position
	//g_camera.rotation = player.rotation
}
