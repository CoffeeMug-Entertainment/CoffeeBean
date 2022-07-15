#include "App.h"
#include "glad/glad.h"

#include <iostream>

namespace CBE
{
	App::App() 
	{
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

		if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
  			std::cout << "Failed to init SDL!\n";
			exit(-1);
  		}

		m_window = SDL_CreateWindow("CoffeeBean",
									SDL_WINDOWPOS_CENTERED,
									SDL_WINDOWPOS_CENTERED,
									800,
									600,
									SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);

		if (m_window == nullptr) {
  			std::cout << "Failed to make window!\n";
			exit(-2);
  		}

		m_context = SDL_GL_CreateContext(m_window);
		
		if(m_context == 0)
		{
			std::cout << "Failed to make OpenGL Context!\n";
			std::cout << SDL_GetError() << std::endl;
			exit(-3);
		}

		if(!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
		{
			std::cout << "Failed to initialise GLAD!\n";
			exit(-4);
		}

		m_running = true;
	}

	App::~App() 
	{
		SDL_GL_DeleteContext(m_context);
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}
	
	int App::Loop()
	{
		glClearColor(0.75f, 1.0f, 0.93f, 1.0f); //#C0FFEE
		while(m_running)
		{
			ProcessEvents();
			glClear(GL_COLOR_BUFFER_BIT);
			SDL_GL_SwapWindow(m_window);
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
