#include "Model.h"
#include "Renderer/Mesh.h"
#include "Renderer/Texture.h"
#include "Shader.h"
#include "App.h"

#include "Importers/ObjImporter.hpp"
#include "stb_image.h"
#include "fmt/core.h"
#include <filesystem>

namespace CBE
{
	void Model::Draw()
	{
		shaderProgram->Use();
		
		shaderProgram->Uniform1i("ticks", App::Instance().ticks);

		for (Mesh& mesh : meshes) 
		{
			mesh.vao.Bind();
			glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
			mesh.vao.Unbind();
		}

		glUseProgram(0);
	}

	void Model::Load(std::string& path)
	{
		CBE::Mesh tempMesh;
		if(LoadMeshFromOBJ(path, tempMesh)) 
		{
			tempMesh.Setup();
			this->meshes.emplace_back(tempMesh);
		}
		else 
		{
			fmt::print("Failed to load Model: {}", path);
		}
		return;
	}

}
