#ifndef CBE_APP_H
#define CBE_APP_H

#include "Renderer/Renderer.h"

#include "SDL.h"

#include <memory>

namespace CBE
{
	class App 
	{	
		public:
			App();
			~App();
			void Render();
			int Loop();
			static App& Instance() {return *s_instance;}
			unsigned long long ticks;
		private:

			static App* s_instance;
			//TODO(Fix): Smart pointers - unique_ptr
			SDL_Window* m_window;
			std::unique_ptr<Renderer> m_renderer;
			SDL_Event m_event;

			bool m_running;

			void ProcessEvents();

	};
}

#endif
