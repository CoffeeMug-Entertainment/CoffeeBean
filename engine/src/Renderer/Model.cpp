#include "Model.h"
#include "Shader.h"
#include "App.h"

#include "assimp/Importer.hpp"
#include "assimp/scene.h"
#include "assimp/postprocess.h"
#include "spdlog/spdlog.h"

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

	Mesh ProcessMesh(aiMesh* mesh, const aiScene* scene)
	{
		Mesh newMesh;

		for(unsigned int i = 0; i < mesh->mNumVertices; ++i)
		{
			newMesh.EmplaceVertex(
					glm::vec3
					{
						mesh->mVertices[i].x,
						mesh->mVertices[i].y,
						mesh->mVertices[i].z
					}
				);
				if(mesh->mTextureCoords[0])
				{
					newMesh.vertices[i].texCoords = glm::vec2{mesh->mTextureCoords[0][i].x, mesh->mTextureCoords[0][i].y};
				}
		}

		for(unsigned int i = 0; i < mesh->mNumFaces; ++i)
		{
			for(unsigned int j = 0; j < mesh->mFaces[i].mNumIndices; ++j)
			{
				newMesh.indices.emplace_back(mesh->mFaces[i].mIndices[j]);
			}
		}

		return newMesh;
	}

	void ProcessNode(Model& mdl, aiNode* node, const aiScene* scene)
	{
		for(unsigned int i = 0; i < node->mNumMeshes; ++i)
		{
			aiMesh* mesh = scene->mMeshes[node->mMeshes[i]];
			CBE::Mesh tempMesh = ProcessMesh(mesh, scene);
			tempMesh.Setup();
			mdl.meshes.emplace_back(tempMesh);
		}

		for(unsigned int i = 0; i < node->mNumChildren; ++i)
		{
			ProcessNode(mdl, node->mChildren[i], scene);
		}
	}

	void Model::Load(std::string& path)
	{
		Assimp::Importer importer;
		const aiScene* scene = importer.ReadFile(path, aiProcess_Triangulate | aiProcess_FlipUVs);

		if(!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode)
		{
			spdlog::error("Assimp failed to import file {}\n\tReason: {}", path, importer.GetErrorString());
		}
		
		ProcessNode(*this, scene->mRootNode, scene);
	}
}
