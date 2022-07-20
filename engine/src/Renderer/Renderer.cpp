#include "Renderer.h"
#include "glad/glad.h"
#include "spdlog/spdlog.h"

namespace CBE
{
	Renderer::Renderer(SDL_Window* window)
	{
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
		//SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);

		m_context = SDL_GL_CreateContext(window);

		
		if(m_context == 0)
		{
			spdlog::error("Failed to make OpenGL context!\n\t{}", SDL_GetError());
			exit(-3);
		}

		SDL_GL_SetSwapInterval(1);

		if(!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
		{
			spdlog::error("Failed to initialise GLAD!\n");
			exit(-4);
		}
		glViewport(0, 0, 800, 600);
		glDisable(GL_DEPTH_TEST);
		glDisable(GL_CULL_FACE);

		spdlog::info("\nOpenGL Info:\n\tVendor: {}\n\tRenderer: {}\n\tVersion: {}", glGetString(GL_VENDOR), glGetString(GL_RENDERER), glGetString(GL_VERSION));
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

	void Renderer::DrawTri()
	{
		glDrawArrays(GL_TRIANGLES, 0, 3);
	}

	void Renderer::SetClearColor(glm::vec4&& newColor)
	{
		m_clearColor = newColor;
		glClearColor(m_clearColor.r, m_clearColor.g, m_clearColor.b, m_clearColor.a);
	}
}
