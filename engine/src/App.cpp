#include "App.h"
#include "glad/glad.h"
#include "spdlog/spdlog.h"

#include "Renderer/Shader.h"
#include "Renderer/DefaultShaders.h"
#include "Renderer/Buffers.h"
#include "Entities/Components.h"
#include "Entities/Entity.h"
#include "Renderer/Model.h"

#include "glm/gtc/type_ptr.hpp"
#include "stb_image.h"

#include <iostream>

namespace CBE
{
	//TEMP(Fix): Just to draw something in the world
	//Model g_triangle;
	Model g_rect;
	Entity g_rectObj;

	Texture g_testTexture;
	
	App* App::s_instance = nullptr;


	App::App() 
	{
		if (s_instance) {
			spdlog::error("App instance already exits!");
			return;
		}

		s_instance = this;


		if (SDL_Init(SDL_INIT_EVERYTHING) != 0) {
			spdlog::error("Failed to init SDL!\n\t{}", SDL_GetError());
			exit(-1);
		}

		m_window = SDL_CreateWindow("CoffeeBean",
									SDL_WINDOWPOS_CENTERED,
									SDL_WINDOWPOS_CENTERED,
									800,
									600,
									SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);

		if (m_window == nullptr) {
			spdlog::error("Failed to make window!\n\t{}", SDL_GetError());
			exit(-2);
		}

		m_renderer = std::unique_ptr<Renderer>(new Renderer(m_window));
		m_renderer->camera.ToDefault();
		m_running = true;
		ticks = 0;

		SDL_SetRelativeMouseMode(SDL_TRUE);

		//TEMP(fix): Just to mess around with OpenGL
		stbi_set_flip_vertically_on_load(true);

		g_testTexture.width = 1;
		g_testTexture.height = 1;
		g_testTexture.comps = 4;
		std::string a = "test.png";
		unsigned char* test_img_data = g_testTexture.Load(a);
		//g_testTexture.PushToGPU(WHITE_PIXEL_DATA);
		g_testTexture.PushToGPU(test_img_data);
		stbi_image_free(test_img_data);

		Mesh temp;
#define DRAW_RECT

#if defined(DRAW_RECT)
		temp.EmplaceVertex(glm::vec3{-0.5f, 0.5f, 0.0f}, glm::vec4{1.0f, 0.0f, 0.0f, 1.0f}, glm::vec2{0.0f, 1.0f});
		temp.EmplaceVertex(glm::vec3{-0.5f, -0.5f, 0.0f}, glm::vec4{0.0f, 1.0f, 0.0f, 1.0f}, glm::vec2{0.0f, 0.0f});
		temp.EmplaceVertex(glm::vec3{0.5f, -0.5f, 0.0f}, glm::vec4{0.0f, 0.0f, 1.0f, 1.0f}, glm::vec2{1.0f, 0.0f});
		temp.EmplaceVertex(glm::vec3{0.5f, 0.5f, 0.0f}, glm::vec4{1.0f, 1.0f, 1.0f, 1.0f}, glm::vec2{1.0f, 1.0f});

		temp.indices.emplace_back(0);
		temp.indices.emplace_back(1);
		temp.indices.emplace_back(3);
		temp.indices.emplace_back(1);
		temp.indices.emplace_back(2);
		temp.indices.emplace_back(3);
#endif

#if !defined(DRAW_RECT) && defined(DRAW_HEX)
		temp.EmplaceVertex();
		temp.EmplaceVertex(glm::vec3{-0.5, 0.0, 0.0}, glm::vec4{1.0f, 0.0f, 0.0f, 1.0f}); //left
		temp.EmplaceVertex(glm::vec3{-0.25, -0.5, 0.0}, glm::vec4{0.0f, 1.0f, 0.0f, 1.0f}); //bottom left
		temp.EmplaceVertex(glm::vec3{0.25, -0.5, 0.0}, glm::vec4{0.0f, 0.0f, 1.0f, 1.0f}); // bottom right
		temp.EmplaceVertex(glm::vec3{0.5, 0.0, 0.0}, glm::vec4{1.0f, 0.0f, 0.0f, 1.0f}); //right
		temp.EmplaceVertex(glm::vec3{0.25, 0.5, 0.0}, glm::vec4{0.0f, 1.0f, 0.0f, 1.0f}); //top right
		temp.EmplaceVertex(glm::vec3{-0.25, 0.5, 0.0}, glm::vec4{0.0f, 0.0f, 1.0f, 1.0f}); //top left

		for(int i = 0; i <= 5; ++i)
		{
			temp.indices.emplace_back(0);
			temp.indices.emplace_back(i);
			temp.indices.emplace_back(i + 1);
		}

			temp.indices.emplace_back(0);
			temp.indices.emplace_back(6);
			temp.indices.emplace_back(1);
#endif
		temp.Setup();

		//g_rect.meshes.emplace_back(temp);
		std::string modelPath = "teapot.obj";
		g_rect.Load(modelPath);
		spdlog::info("Test model has {} meshes", g_rect.meshes.size());
		for(unsigned int i = 0; i < g_rect.meshes.size(); ++i)
		{
			spdlog::info("Mesh {} has {} vertices and {} indices", i, g_rect.meshes[i].vertices.size(), g_rect.meshes[i].indices.size());
		}
		g_rect.texture = &g_testTexture;
		g_rect.shaderProgram = new ShaderProgram();

		Shader* vShader = new Shader(Shader::VERT, DEFAULT_VERT_SHADER_SRC, "DEFAULT_VERT_SHADER_SRC");
		Shader* fShader = new Shader(Shader::FRAG, DEFAULT_FRAG_SHADER_SRC, "DEFAULT_FRAG_SHADER_SRC");

		vShader->Compile();
		fShader->Compile();

		g_rect.shaderProgram->AttachVertShader(vShader);
		g_rect.shaderProgram->AttachFragShader(fShader);
		g_rect.shaderProgram->Link();

		g_rect.shaderProgram->Use();
		g_rect.shaderProgram->Uniform1i("aTexture", 0);

		glUseProgram(0);

		g_rectObj.AddTransform();
		g_rectObj.AddModel(g_rect);
	}

	App::~App() 
	{
		SDL_DestroyWindow(m_window);
		SDL_Quit();
	}

	//TEMP(Fix)
	void DrawSystem(Entity& ent)
	{
		TransformComp* trans = ent.transform;
		ModelComp* modComp = ent.modelComp;

		modComp->model.shaderProgram->Use();
		
		modComp->model.shaderProgram->UniformMatrix4fv("transform", 1, GL_FALSE, ::glm::value_ptr(trans->Matrix()));
		modComp->model.shaderProgram->UniformMatrix4fv("projection", 1, GL_FALSE, ::glm::value_ptr(App::Instance().m_renderer->camera.ProjectionMatrix()));
		modComp->model.shaderProgram->UniformMatrix4fv("view", 1, GL_FALSE, ::glm::value_ptr(App::Instance().m_renderer->camera.ViewMatrix()));
		modComp->model.shaderProgram->Uniform1i("ticks", App::Instance().ticks);

		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, modComp->model.texture->id);

		for (Mesh& mesh : modComp->model.meshes) 
		{
			mesh.vao.Bind();
			glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
			mesh.vao.Unbind();
		}

		glUseProgram(0);
		
	}

	void App::Render()
	{
		m_renderer->Begin();
		
		//TODO(fix): per model
		DrawSystem(g_rectObj);
		//g_rectObj.transform->rotation.z += 15.0f * deltaTime;

		m_renderer->End();
		SDL_GL_SwapWindow(m_window);
	}
	
	int App::Loop()
	{
		m_renderer->SetClearColor({0.75f, 1.0f, 0.93f, 1.0f});
		while(m_running)
		{
			oldTicks = ticks;
			ticks = SDL_GetTicks64();
			//deltaTicks = ticks - oldTicks;
			deltaTime = (ticks - oldTicks) / 1000.0f;
			ProcessEvents();
			Render();	
		}

		return 0;
	}

	void App::ProcessEvents()
	{
		glm::vec2 mouseMovement; 
		while(SDL_PollEvent(&m_event))
		{
			switch(m_event.type)
			{
				case SDL_QUIT:
					m_running = false;
					break;
				case SDL_KEYDOWN:
					if(m_event.key.keysym.sym == SDLK_ESCAPE) {m_running = false;}
	//TEMP(fhomolka): just a neat place to move around
#if 1
					if(m_event.key.keysym.sym == SDLK_a) 
					{
						m_renderer->camera.position -= m_renderer->camera.right;
					}
					if(m_event.key.keysym.sym == SDLK_d) 
					{
						m_renderer->camera.position += m_renderer->camera.right;
					}
					if(m_event.key.keysym.sym == SDLK_w) 
					{
						m_renderer->camera.position += m_renderer->camera.forward;
					}
					if(m_event.key.keysym.sym == SDLK_s) 
					{
						m_renderer->camera.position -= m_renderer->camera.forward;
					}
#endif
					break;
				case SDL_MOUSEMOTION:
#if 1
					mouseMovement = glm::vec2{m_event.motion.xrel, m_event.motion.yrel};
					m_renderer->camera.MouseLook(mouseMovement,  deltaTime * 4);
					//m_renderer->camera.target.x += mouseMovement.x * deltaTime;
					//m_renderer->camera.target.y -= mouseMovement.y * deltaTime;
#endif
					break;
				default:
					break;
			}
		}
	}
}
