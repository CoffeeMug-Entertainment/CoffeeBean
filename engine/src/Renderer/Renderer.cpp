#include "Renderer.h"
#include "glad/glad.h"
#include "spdlog/spdlog.h"

namespace CBE
{
	Renderer::Renderer(SDL_Window* window)
	{
		m_context = SDL_GL_CreateContext(window);

		
		if(m_context == 0)
		{
			spdlog::error("Failed to make OpenGL context!\n\t{}", SDL_GetError());
			exit(-3);
		}

		if(!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
		{
			spdlog::error("Failed to initialise GLAD!\n");
			exit(-4);
		}
	}
	
	Renderer::~Renderer()
	{
		SDL_GL_DeleteContext(m_context);
	}

	void Renderer::Begin()
	{
		//glViewport(0, 0, 800, 600);
		glClear(GL_COLOR_BUFFER_BIT);
	}

	void Renderer::End()
	{

	}

	void Renderer::DrawTri(glm::vec3& position, std::array<float, 9>& vertices)
	{
		
	}

	void Renderer::SetClearColor(glm::vec4&& newColor)
	{
		m_clearColor = newColor;
		glClearColor(m_clearColor.r, m_clearColor.g, m_clearColor.b, m_clearColor.a);
	}
}
