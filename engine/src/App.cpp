#include "App.h"
#include "SDL_keycode.h"
#include "entt/entity/fwd.hpp"
#include "glad/glad.h"
#include "glm/ext/vector_float3.hpp"
#include "glm/fwd.hpp"
#include "spdlog/spdlog.h"

#include "Renderer/Shader.h"
#include "Renderer/DefaultShaders.h"
#include "Renderer/Buffers.h"
#include "Entities/Components.h"
#include "Entities/Entity.h"
#include "Renderer/Model.h"
#include "Input/Input.h"

#include "glm/gtc/type_ptr.hpp"
#include <glm/gtx/rotate_vector.hpp>
#include "stb_image.h"

#include <SDL2/SDL_events.h>
#include <X11/Xutil.h>
#include <iostream>

namespace CBE
{
	//TEMP(Fix): Just to draw something in the world
	//Model g_triangle;
	Model g_rect;
	Entity g_rectObj;

#if 0
	Model g_light;
	Entity g_lightObj;
#endif

	App* App::s_instance = nullptr;


	App::App() 
	{
		if (s_instance) {
			spdlog::error("App instance already exits!");
			return;
		}

		s_instance = this;


		if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
			spdlog::error("Failed to init SDL!\n\t{}", SDL_GetError());
			exit(-1);
		}

		m_window = SDL_CreateWindow("CoffeeBean",
									SDL_WINDOWPOS_CENTERED,
									SDL_WINDOWPOS_CENTERED,
									1280,
									720,
									SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);

		if (m_window == nullptr) {
			spdlog::error("Failed to make window!\n\t{}", SDL_GetError());
			exit(-2);
		}

		m_renderer = std::unique_ptr<Renderer>(new Renderer(m_window));
		m_renderer->camera.ToDefault();
		m_running = true;
		ticks = 0;

		SDL_SetRelativeMouseMode(SDL_TRUE);

		//TEMP(fix): Just to mess around with OpenGL
		stbi_set_flip_vertically_on_load(true);

		std::string modelPath = "box.obj";
		g_rect.Load(modelPath);

		g_rect.shaderProgram = new ShaderProgram();

		Shader* vShader = new Shader(Shader::VERT, DEFAULT_VERT_SHADER_SRC, "DEFAULT_VERT_SHADER_SRC");
		Shader* fShader = new Shader(Shader::FRAG, DEFAULT_FRAG_SHADER_SRC, "DEFAULT_FRAG_SHADER_SRC");

		vShader->Compile();
		fShader->Compile();

		g_rect.shaderProgram->AttachVertShader(vShader);
		g_rect.shaderProgram->AttachFragShader(fShader);
		g_rect.shaderProgram->Link();

		glUseProgram(g_rect.shaderProgram->m_id);
		g_rect.shaderProgram->Uniform1i("aTexture", 0);

		glUseProgram(0);

		g_rectObj.Create();
		m_entityRegistry.emplace<ModelComp>(g_rectObj.enttID, g_rect);

		RegisterKey("quit", SDLK_ESCAPE);
		RegisterKey("move_forward", SDLK_w);
		RegisterKey("move_left", SDLK_a);
		RegisterKey("move_back", SDLK_s);
		RegisterKey("move_right", SDLK_d);
		RegisterKey("move_up", SDLK_SPACE);
		RegisterKey("move_down", SDLK_c);
		RegisterKey("move_fast", SDLK_f);

		RegisterKey("cube_forward", SDLK_UP);
		RegisterKey("cube_back", SDLK_DOWN);
		RegisterKey("cube_left", SDLK_LEFT);
		RegisterKey("cube_right", SDLK_RIGHT);
	}

	App::~App() 
	{
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}

	//TEMP(Fix)
	void DrawSystem(TransformComp& trans, ModelComp& modComp)
	{
		glUseProgram(modComp.model.shaderProgram->m_id);
		
		modComp.model.shaderProgram->Uniform1i("ticks", App::Instance().ticks);
		glm::mat4 mvp = App::Instance().m_renderer->camera.ProjectionMatrix() * App::Instance().m_renderer->camera.ViewMatrix() * trans.Matrix();
		modComp.model.shaderProgram->UniformMatrix4fv("mvp", 1, GL_FALSE, ::glm::value_ptr(mvp));

		for (Mesh& mesh : modComp.model.meshes) 
		{
			glActiveTexture(GL_TEXTURE0);
			glBindTexture(GL_TEXTURE_2D, mesh.texture->id);
			mesh.vao.Bind();
			glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
			mesh.vao.Unbind();
		}

		glUseProgram(0);
	}

	void App::Render()
	{
		m_renderer->Begin();
		
		auto entities = m_entityRegistry.view<TransformComp, ModelComp>();
		for(auto entity : entities)
		{
			TransformComp& trans = entities.get<TransformComp>(entity);
			ModelComp& model = entities.get<ModelComp>(entity);
			DrawSystem(trans, model);
		}

		m_renderer->End();
		SDL_GL_SwapWindow(m_window);
	}



	void App::Update()
	{
		//TEMP(Fix): This belongs in scripting, but it'll do nicely here for now
		if(IsPressed("quit"))
		{
			m_running = false;
			return;
		}

		static float speed = 1.0f;

		if(IsPressed("move_fast")) 
			speed = 16.0f;
		else
			speed = 1.0f;

		if(IsPressed("move_left"))
			m_renderer->camera.position -= m_renderer->camera.right * deltaTime * speed;
		if(IsPressed("move_right"))
			m_renderer->camera.position += m_renderer->camera.right * deltaTime * speed;
		if(IsPressed("move_forward"))
			m_renderer->camera.position += m_renderer->camera.forward * deltaTime * speed;
		if(IsPressed("move_back"))
			m_renderer->camera.position -= m_renderer->camera.forward * deltaTime * speed;
		if(IsPressed("move_up"))
			m_renderer->camera.position += m_renderer->camera.up * deltaTime * speed;
		if(IsPressed("move_down"))
			m_renderer->camera.position -= m_renderer->camera.up * deltaTime * speed;

		if(IsPressed("cube_forward"))
			g_rectObj.Transform().position += glm::rotateY(glm::vec3(1, 0, 0), glm::radians(g_rectObj.Transform().rotation.y)) * deltaTime;
		if(IsPressed("cube_back"))
			g_rectObj.Transform().position += glm::rotateY(glm::vec3(-1, 0, 0), glm::radians(g_rectObj.Transform().rotation.y)) * deltaTime;
		if(IsPressed("cube_left"))
			g_rectObj.Transform().rotation.y += 45 * deltaTime;
		if(IsPressed("cube_right"))
			g_rectObj.Transform().rotation.y -= 45 * deltaTime;
	}
	
	int App::Loop()
	{
		m_renderer->SetClearColor({0.75f, 1.0f, 0.93f, 1.0f});
		while(m_running)
		{
			oldTicks = ticks;
			ticks = SDL_GetTicks64();
			//deltaTicks = ticks - oldTicks;
			deltaTime = (ticks - oldTicks) / 1000.0f;
			ProcessEvents();
			Update();
			Render();	
		}

		return 0;
	}

	void App::ProcessEvents()
	{
		glm::vec2 mouseMovement; 
		while(SDL_PollEvent(&m_event))
		{
			switch(m_event.type)
			{
				case SDL_QUIT:
					m_running = false;
					break;
				case SDL_KEYDOWN:
					[[fallthrough]];
				case SDL_KEYUP:
					UpdateInput(m_event.key.keysym.sym, m_event.type == SDL_KEYDOWN);
					break;
				case SDL_MOUSEMOTION:
#if 1
					mouseMovement = glm::vec2{m_event.motion.xrel, m_event.motion.yrel};
					m_renderer->camera.MouseLook(mouseMovement,  deltaTime * 4);
#endif
					break;
				default:
					break;
			}
		}
	}
}
