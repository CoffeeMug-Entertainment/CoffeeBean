#include "App.h"
#include "glad/glad.h"
#include "spdlog/spdlog.h"

#include "Renderer/Shader.h"
#include "Renderer/DefaultShaders.h"
#include "Renderer/Buffers.h"
#include "Renderer/Model.h"

#include <iostream>

namespace CBE
{
	//TEMP(Fix): Just to draw something in the world
	Model g_triangle;

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

		//TEMP(fix): Just to mess around with OpenGL
		Mesh temp;
		temp.vertices.emplace_back(Vertex{glm::vec3{-0.5f, -0.5f, 0.0f}});
		temp.vertices.emplace_back(Vertex{glm::vec3{0.5f, -0.5f, 0.0f}});
		temp.vertices.emplace_back(Vertex{glm::vec3{0.0f, 0.5f, 0.0f}});

		temp.indices.emplace_back(0);
		temp.indices.emplace_back(1);
		temp.indices.emplace_back(2);

		temp.Setup();
		
		g_triangle.meshes.emplace_back(temp);

		g_triangle.shaderProgram = new ShaderProgram();

		Shader* vShader = new Shader(Shader::VERT, DEFAULT_VERT_SHADER_SRC, "DEFAULT_VERT_SHADER_SRC");
		Shader* fShader = new Shader(Shader::FRAG, DEFAULT_FRAG_SHADER_SRC, "DEFAULT_FRAG_SHADER_SRC");

		vShader->Compile();
		fShader->Compile();

		g_triangle.shaderProgram->AttachVertShader(vShader);
		g_triangle.shaderProgram->AttachFragShader(fShader);
		g_triangle.shaderProgram->Link();

	}

	App::~App() 
	{
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}

	void App::Render()
	{
		m_renderer->Begin();
		
		//TODO(fix): per model
		g_triangle.Draw();

		m_renderer->End();
		SDL_GL_SwapWindow(m_window);
	}
	
	int App::Loop()
	{
		m_renderer->SetClearColor({0.75f, 1.0f, 0.93f, 1.0f});
		while(m_running)
		{
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
