package CBE

import "libs:mdf"
import "../shared"

import glm "core:math/linalg/glsl"
import SDL "vendor:sdl2"
import gl "vendor:OpenGL"
import stbi "vendor:stb/image"

import "core:log"
import "core:strings"
import "core:strconv"
import "core:dynlib"
import "core:fmt"

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
	entities: [1024]shared.Entity,
	entity_count: u32,

	//Gamecode
	game: dynlib.Library,
	game_ui: proc(),
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

key_released :: proc(sc: SDL.Scancode) -> bool
{
	return g_app.keyboard_state[sc] == 0 && g_app.last_keyboard_state[sc] > 0
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
	gl.CullFace(gl.BACK)
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

	//Gamecode
	GAMECODE_PATH :: "basegame/game.so"
	gamecode_loaded: bool
	g_app.game, gamecode_loaded = dynlib.load_library(GAMECODE_PATH)
	if !gamecode_loaded {log.errorf("Failed to load gamecode: %v\n", GAMECODE_PATH)}

	game_init := cast(proc(shared.EngineInterface))dynlib.symbol_address(g_app.game, "game_init")

	if game_init == nil {log.errorf("Failed to find game_init inside %v\n", GAMECODE_PATH)}
	else 
	{
		ei : shared.EngineInterface
		ei.entity_create = entity_create
		ei.load_model_m3d = load_model_m3d
		ei.key_down = key_down
		ei.key_pressed = key_pressed
		ei.key_released = key_released
		ei.camera = &g_camera
		ei.delta_time = &g_app.delta_time
		ei.screen_print = screen_print
		ei.screen_tprintf = screen_tprintf
		game_init(ei)

		g_app.game_ui = cast(proc())dynlib.symbol_address(g_app.game, "game_ui")
	}

	// Text Rendering

	//log.info("Compiling text shader")
	text_program, text_ok := gl.load_shaders_source(VERTEX_TEXT_SRC, FRAGMENT_TEXT_SRC)
	if !text_ok {log.error("GLSL Error: ", gl.get_last_error_message()); return false}

	g_text_program = text_program
	g_text_program_uniforms = gl.get_uniforms_from_program(g_text_program)
	

	gl.GenVertexArrays(1, &quad_vao)
	gl.BindVertexArray(quad_vao)

	gl.GenBuffers(1, &quad_vbo)
	gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo)
	gl.BufferData(gl.ARRAY_BUFFER, 4 * size_of(glm.vec4), nil, gl.DYNAMIC_DRAW)

	gl.EnableVertexAttribArray(0)
	gl.VertexAttribPointer(0, 4, gl.FLOAT, false, size_of(glm.vec4), 0)

	gl.GenBuffers(1, &quad_ebo)
	gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ebo)
	gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(quad_idx) * size_of(quad_idx[0]), raw_data(quad_idx), gl.STATIC_DRAW)

	load_font_image("./basegame/fonts/FontCodeMonospace.png")

	g_app.running = true

	return true
}

app_shutdown :: proc()
{
	//QUESTION(fhomolka): Do we even care about freeing some of these in release mode?
	gl.destroy_uniforms(g_app.screen_shaderuniforms)
	gl.destroy_uniforms(g_uniforms)

	if g_text_program != 0 do gl.destroy_uniforms(g_text_program_uniforms)

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

	for _, font in g_app.fonts
	{
		delete(font.glyphs)
	}
	delete(g_app.fonts)


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

	dynlib.unload_library(g_app.game)

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
	proj := glm.mat4Perspective(1, 16.0/9.0, 0.05, 4096.0)

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

	g_app.game_ui()
	
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
			gl.BindTexture(gl.TEXTURE_2D, g_app.textures[smesh_ref.material].ID)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
			gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
			
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

			//zzz
			//TEMP(Fix): This is here for compatibility with old .map formats
			if !strings.contains(smesh.material, "/")
			{
				temp_path := fmt.tprintf("./%v/textures/%v.tga", GAMEDIR, smesh.material)
				smesh.material = strings.clone(temp_path)
				
			}

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

VERTEX_TEXT_SRC :: #load("./shaders/default_text_vertex.glsl", string)
FRAGMENT_TEXT_SRC :: #load("./shaders/default_text_fragment.glsl", string)

GLYPHS_HORIZONTAL :: 16
GLYPHS_VERTICAL :: 8

quad_idx : []u16 = 
{ 
	0, 1, 2, 
	0, 2, 3,
}

quad_vtx : [4]glm.vec3 =
{
	glm.vec3{0, 0, 0},
	glm.vec3{0, 1, 0},
	glm.vec3{1, 1, 0},
	glm.vec3{1, 0, 0},
}

quad_vao: u32
quad_vbo: u32
quad_ebo: u32

g_text_program: u32
g_text_program_uniforms: gl.Uniforms

Glyph :: struct
{
	uvs : [4]glm.vec2,
	uv_vbo: u32,
}

Font :: struct
{
	glyphs: map[rune]Glyph,
	texture: string,
	
	u_projection: glm.mat4,
}

load_font_image :: proc(path: string) -> bool
{
	load_texture(path)
	push_image_to_GPU(path)
	
	texture := &g_app.textures[path]
	new_font : Font 
	new_font.texture = path

	char_width := texture.width / GLYPHS_HORIZONTAL
	char_height := texture.height / GLYPHS_VERTICAL

	x : i32 = 0
	y : i32 = 0

	// Skip first 32 invisible symbols, Start from Space
	for c in 32..<128
	{
		char := cast(rune)c
		
		g : Glyph 
		g.uvs = 
		{
			glm.vec2{f32(x) / f32(texture.width), f32(y) / f32(texture.height)},
			glm.vec2{f32(x) / f32(texture.width), f32(y + char_height) / f32(texture.height)},
			glm.vec2{f32(x + char_width) / f32(texture.width) , f32(y + char_height) / f32(texture.height)},
			glm.vec2{f32(x + char_width) / f32(texture.width), f32(y)/ f32(texture.height)},
		}

		new_font.glyphs[char] = g

		x += char_width

		if x >= texture.width 
		{
			x = 0
			y += char_height
			if y >= texture.width do y = 0
		}
	}

	g_app.fonts[path] = new_font
	return true
}

screen_print :: proc(font_name: string, position: glm.vec2, scale: f32, text: string)
{
	gl.UseProgram(g_text_program)
	gl.BindVertexArray(quad_vao)
	
	u_projection := glm.mat4Ortho3d(0, 1280, 720, 0, 0.1, 1000)
	gl.UniformMatrix4fv(g_text_program_uniforms["u_projection"].location, 1, false, &u_projection[0, 0])

	font := &g_app.fonts[font_name]
	texture := &g_app.textures[font.texture]
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture.ID)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

	x : f32 = position.x
	y : f32 = position.y
	w : f32 = f32(texture.width) / 16.0
	h : f32 = f32(texture.height) / 8.0

	for c in text
	{
		if c == '\n'
		{
			y += h * scale
			x = position.x
			continue
		}

		glyph := &font.glyphs[c]

		char_vtx : [4]glm.vec4 =
		{
			{x,				y,			   glyph.uvs[0].x, glyph.uvs[0].y},
			{x,				y + h * scale, glyph.uvs[1].x, glyph.uvs[1].y},
			{x + w * scale, y + h * scale, glyph.uvs[2].x, glyph.uvs[2].y},
			{x + w * scale, y,			   glyph.uvs[3].x, glyph.uvs[3].y},
		}
		//fmt.println(char_vtx)

		gl.BindBuffer(gl.ARRAY_BUFFER, quad_vbo)
		gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(char_vtx) * size_of(char_vtx[0]), raw_data(&char_vtx))
		//gl.DrawArrays(gl.TRIANGLES, 0, 6)

		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, quad_ebo)
		gl.DrawElements(gl.TRIANGLES, i32(len(quad_idx)), gl.UNSIGNED_SHORT, nil)

		x += w * scale
	}
}

screen_tprintf :: proc(font_name: string, position: glm.vec2, scale: f32, format: string, args : ..any)
{
	screen_print(font_name, position, scale, fmt.tprintf(format, ..args))
}

g_camera: shared.Camera

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

entity_create :: proc() -> ^shared.Entity
{
	en := &g_app.entities[g_app.entity_count]
	en.flags |= {.VALID}

	g_app.entity_count += 1

	return en
}

entity_render :: proc(en: ^shared.Entity, view_matrix: glm.mat4, proj_matrix: glm.mat4)
{
	transform_matrix := glm.identity(glm.mat4)
	transform_matrix += glm.mat4Translate(en.position)
	transform_matrix *= glm.mat4Rotate(glm.vec3{1, 0, 0}, glm.radians(en.rotation.x))
	transform_matrix *= glm.mat4Rotate(glm.vec3{0, 1, 0}, glm.radians(en.rotation.y))
	transform_matrix *= glm.mat4Rotate(glm.vec3{0, 0, 1}, glm.radians(en.rotation.z))

	model := &g_app.models[en.model]
	model_render(model, transform_matrix, proj_matrix, view_matrix)
	
}

GAMEDIR :: "basegame"