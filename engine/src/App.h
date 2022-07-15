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
		private:
			//TODO(Fix): Smart pointers - unique_ptr
			SDL_Window* m_window;
			SDL_Event m_event;

			bool m_running;

			void ProcessEvents();

	};
}

#endif
