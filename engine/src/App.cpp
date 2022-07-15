#include "App.h"

#include <iostream>

namespace CBE
{
	App::App() 
	{
		if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
  			std::cout << "Failed to init SDL!\n";
			exit(-1);
  		}

		m_window = SDL_CreateWindow("CoffeeBean",
									SDL_WINDOWPOS_CENTERED,
									SDL_WINDOWPOS_CENTERED,
									800,
									600,
									SDL_WINDOW_SHOWN);

		if (m_window == nullptr) {
  			std::cout << "Failed to make window!\n";
			exit(-2);
  		}

		m_running = true;
	}

	App::~App() 
	{
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}
	
	int App::Loop()
	{
		while(m_running)
		{
			ProcessEvents();
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
