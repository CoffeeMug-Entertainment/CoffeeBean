#ifndef CBE_APP_H
#define CBE_APP_H

#include "SDL.h"

#include <memory>

namespace CBE
{
	class App 
	{	
		public:
			App();
			~App();
			int Loop();
			static App& Instance() {return *s_instance;}
		private:

			static App* s_instance;
			//TODO(Fix): Smart pointers - unique_ptr
			SDL_Window* m_window;
			SDL_GLContext m_context;
			SDL_Event m_event;

			bool m_running;

			void ProcessEvents();

	};
}

#endif
