#include "App.h"
#include "glad/glad.h"
#include "spdlog/spdlog.h"

#include <iostream>

namespace CBE
{
	App* App::s_instance = nullptr;


	App::App() 
	{
		if (s_instance) {
			spdlog::error("App instance already exits!");
			return;
  		}

		s_instance = this;

		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

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
	}

	App::~App() 
	{
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}

	void App::Render()
	{
		m_renderer->Begin();
		// TODO(fix) Draw objects
		m_renderer->End();
		SDL_GL_SwapWindow(m_window);
	}
	
	int App::Loop()
	{
		glClearColor(0.75f, 1.0f, 0.93f, 1.0f); //#C0FFEE
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
