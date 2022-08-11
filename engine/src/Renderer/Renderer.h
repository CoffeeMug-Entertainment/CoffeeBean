#ifndef CBE_3D_RENDERER
#define CBE_3D_RENDERER

#include "Camera.h"

#include "glm/vec4.hpp"
#include "glm/mat4x4.hpp"
#include "SDL.h"

#include <array>

namespace CBE
{
	class Renderer
	{
	public:
		Renderer(SDL_Window* window);
		~Renderer();

		void Begin();
		void End();

		void SetClearColor(glm::vec4&& newColor);
		Camera camera;
	private:
		SDL_GLContext m_context;
		glm::mat4 m_viewProjectionMat;
		glm::vec4 m_clearColor;
	};
}
#endif

