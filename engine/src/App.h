#ifndef CBE_APP_H
#define CBE_APP_H

#include "Renderer/Renderer.h"

#include "SDL.h"
#include "entt/entity/fwd.hpp"
#include "entt/entt.hpp"

#include <memory>

namespace CBE
{
	class App 
	{	
		public:
			App();
			~App();
			void Render();
			void Update();
			int Loop();
			static App& Instance() {return *s_instance;}
			unsigned long long ticks;
			unsigned long long oldTicks;
			//unsigned long long deltaTicks;
			float deltaTime;
			std::unique_ptr<Renderer> m_renderer;
			SDL_Window* m_window;
			entt::registry m_entityRegistry;

		private:

			static App* s_instance;
			//TODO(Fix): Smart pointers - unique_ptr
			SDL_Event m_event;

			bool m_running;

			void ProcessEvents();

	};
}

#endif
