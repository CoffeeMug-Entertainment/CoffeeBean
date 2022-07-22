#include "App.h"
#include "glad/glad.h"
#include "spdlog/spdlog.h"

#include "Renderer/Shader.h"
#include "Renderer/DefaultShaders.h"
#include "Renderer/Buffers.h"
#include "Entities/Components.h"
#include "Entities/Entity.h"
#include "Renderer/Model.h"

#include <iostream>

namespace CBE
{
	//TEMP(Fix): Just to draw something in the world
	//Model g_triangle;
	Model g_rect;
	Entity g_rectObj;
	
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
									800,
									600,
									SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);

		if (m_window == nullptr) {
			spdlog::error("Failed to make window!\n\t{}", SDL_GetError());
			exit(-2);
  		}

		m_renderer = std::unique_ptr<Renderer>(new Renderer(m_window));

		m_running = true;
		ticks = 0;

		//TEMP(fix): Just to mess around with OpenGL

		Mesh temp;

#define DRAW_HEX

#if defined(DRAW_RECT)
		temp.EmplaceVertex(glm::vec3{-0.5f, 0.5f, 0.0f}, glm::vec4{1.0f, 0.0f, 0.0f, 1.0f});
		temp.EmplaceVertex(glm::vec3{-0.5f, -0.5f, 0.0f}, glm::vec4{0.0f, 1.0f, 0.0f, 1.0f});
		temp.EmplaceVertex(glm::vec3{0.5f, -0.5f, 0.0f}, glm::vec4{0.0f, 0.0f, 1.0f, 1.0f});
		temp.EmplaceVertex(glm::vec3{0.5f, 0.5f, 0.0f});

		temp.indices.emplace_back(0);
		temp.indices.emplace_back(1);
		temp.indices.emplace_back(3);
		temp.indices.emplace_back(1);
		temp.indices.emplace_back(2);
		temp.indices.emplace_back(3);
#endif

#if !defined(DRAW_RECT) && defined(DRAW_HEX)
		temp.EmplaceVertex();
		temp.EmplaceVertex(glm::vec3{-0.5, 0.0, 0.0}, glm::vec4{1.0f, 0.0f, 0.0f, 1.0f}); //left
		temp.EmplaceVertex(glm::vec3{-0.25, -0.5, 0.0}, glm::vec4{0.0f, 1.0f, 0.0f, 1.0f}); //bottom left
		temp.EmplaceVertex(glm::vec3{0.25, -0.5, 0.0}, glm::vec4{0.0f, 0.0f, 1.0f, 1.0f}); // bottom right
		temp.EmplaceVertex(glm::vec3{0.5, 0.0, 0.0}, glm::vec4{1.0f, 0.0f, 0.0f, 1.0f}); //right
		temp.EmplaceVertex(glm::vec3{0.25, 0.5, 0.0}, glm::vec4{0.0f, 1.0f, 0.0f, 1.0f}); //top right
		temp.EmplaceVertex(glm::vec3{-0.25, 0.5, 0.0}, glm::vec4{0.0f, 0.0f, 1.0f, 1.0f}); //top left

		for(int i = 0; i <= 5; ++i)
		{
			temp.indices.emplace_back(0);
			temp.indices.emplace_back(i);
			temp.indices.emplace_back(i + 1);
		}

			temp.indices.emplace_back(0);
			temp.indices.emplace_back(6);
			temp.indices.emplace_back(1);
#endif
		temp.Setup();

		g_rect.meshes.emplace_back(temp);
		g_rect.shaderProgram = new ShaderProgram();

		Shader* vShader = new Shader(Shader::VERT, DEFAULT_VERT_SHADER_SRC, "DEFAULT_VERT_SHADER_SRC");
		Shader* fShader = new Shader(Shader::FRAG, DEFAULT_FRAG_SHADER_SRC, "DEFAULT_FRAG_SHADER_SRC");

		vShader->Compile();
		fShader->Compile();

		g_rect.shaderProgram->AttachVertShader(vShader);
		g_rect.shaderProgram->AttachFragShader(fShader);
		g_rect.shaderProgram->Link();

		g_rectObj.AddTransform();
		g_rectObj.AddModel(g_rect);
	}

	App::~App() 
	{
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}

	//TEMP(Fix)
	void DrawSystem(Entity& ent)
	{
		TransformComp* trans = ent.transform;
		ModelComp* modComp = ent.modelComp;

		modComp->model.shaderProgram->Use();
		
		modComp->model.shaderProgram->Uniform3f("pos_offset", trans->position.x, trans->position.y, trans->position.z);
		modComp->model.shaderProgram->Uniform1i("ticks", App::Instance().ticks);

		for (Mesh& mesh : modComp->model.meshes) 
		{
			mesh.vao.Bind();
			glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
			mesh.vao.Unbind();
		}

		glUseProgram(0);
		
	}

	void App::Render()
	{
		m_renderer->Begin();
		
		//TODO(fix): per model
		//g_rect.Draw();
		//g_rectObj.modelComp->model.Draw();
		DrawSystem(g_rectObj);

		m_renderer->End();
		SDL_GL_SwapWindow(m_window);
	}
	
	int App::Loop()
	{
		m_renderer->SetClearColor({0.75f, 1.0f, 0.93f, 1.0f});
		while(m_running)
		{
			ticks = SDL_GetTicks64();
			ProcessEvents();
			Render();	
		}

		return 0;
	}

	void App::ProcessEvents()
	{
		SDL_PollEvent(&m_event);

		switch(m_event.type)
		{
			case SDL_QUIT:
				m_running = false;
				break;
			case SDL_KEYDOWN:
				if(m_event.key.keysym.sym == SDLK_ESCAPE) {m_running = false;}
				break;
			default:
				break;
		}
	}
}
