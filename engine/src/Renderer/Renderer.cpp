#include "Renderer.h"
#include "glad/glad.h"
#include "fmt/core.h"

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
			fmt::print("Failed to make OpenGL context!\n\t{}", SDL_GetError());
			exit(-3);
		}

		//NOTE(fhomolka): This is a bit misleadingly named
		//				  It doesn't ask for an interval, just whether you wants VSync or not
		SDL_GL_SetSwapInterval(GL_TRUE);

		if(!gladLoadGLLoader((GLADloadproc)SDL_GL_GetProcAddress))
		{
			fmt::print("Failed to initialise GLAD!\n");
			exit(-4);
		}
		
		int w, h;
		SDL_GL_GetDrawableSize(window, &w, &h);
		glViewport(0, 0, w, h);
		glEnable(GL_DEPTH_TEST);
		//glDisable(GL_CULL_FACE);
		
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		fmt::print("OpenGL Info:\n\tVendor: {}\n\tRenderer: {}\n\tVersion: {}\n", (char*)glGetString(GL_VENDOR), (char*)glGetString(GL_RENDERER), (char*)glGetString(GL_VERSION));
	}
	
	Renderer::~Renderer()
	{
		SDL_GL_DeleteContext(m_context);
	}

	void Renderer::Begin()
	{
		//glViewport(0, 0, 800, 600);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	}

	void Renderer::End()
	{

	}

	void Renderer::SetClearColor(glm::vec4&& newColor)
	{
		m_clearColor = newColor;
		glClearColor(m_clearColor.r, m_clearColor.g, m_clearColor.b, m_clearColor.a);
	}
}
