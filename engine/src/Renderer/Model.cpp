#include "Model.h"
#include "Shader.h"
#include "App.h"

#include "assimp/Importer.hpp"
#include "assimp/scene.h"
#include "assimp/postprocess.h"
#include "spdlog/spdlog.h"
#include "stb_image.h"

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

	Mesh ProcessMesh(aiMesh* mesh, const aiScene* scene, std::string& path)
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
		
		//TODO(fhomolka): Multiple textures and embeded textures
		Texture* newTex = new Texture();
		if(mesh->mMaterialIndex > 0)
		{
			aiString texPath;
			scene->mMaterials[mesh->mMaterialIndex]->GetTexture(aiTextureType_DIFFUSE, 0,  &texPath);
			std::string texPathStr = std::string(texPath.C_Str());

			//HACK(fhomolka): On some system, stb_image expects an ABSOLUTE path. For now, i did ugly nonsense.
			std::filesystem::path mdlPath = std::filesystem::path(path);
			std::string texDir = mdlPath.parent_path().string();
			std::string fullTexDirStr = texDir + "/" + texPathStr;

			unsigned char* data = newTex->Load(fullTexDirStr);
			if (!data) 
			{
				newTex->width = MISSING_TEX.width;
				newTex->height = MISSING_TEX.height;
				newTex->comps = MISSING_TEX.comps;
   				newTex->PushToGPU(MISSING_TEX_DATA);
			}
			else
			{
				newTex->PushToGPU(data);
			}
			stbi_image_free(data);

		}
		else
		{
			newTex->width = MISSING_TEX.width;
			newTex->height = MISSING_TEX.height;
			newTex->comps = MISSING_TEX.comps;
			newTex->PushToGPU(MISSING_TEX_DATA);
			
		}

		newMesh.texture = newTex;


		return newMesh;
	}

	void ProcessNode(Model& mdl, aiNode* node, const aiScene* scene, std::string& path)
	{
		for(unsigned int i = 0; i < node->mNumMeshes; ++i)
		{
			aiMesh* mesh = scene->mMeshes[node->mMeshes[i]];
			CBE::Mesh tempMesh = ProcessMesh(mesh, scene, path);
			tempMesh.Setup();
			mdl.meshes.emplace_back(tempMesh);
		}

		for(unsigned int i = 0; i < node->mNumChildren; ++i)
		{
			ProcessNode(mdl, node->mChildren[i], scene, path);
		}
	}

	void Model::Load(std::string& path)
	{
		spdlog::info("Importing model from path {}\n", path);
		Assimp::Importer importer;
		const aiScene* scene = importer.ReadFile(path, aiProcess_Triangulate | aiProcess_FlipUVs);

		if(!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode)
		{
			spdlog::error("Assimp failed to import file {}\n\tReason: {}", path, importer.GetErrorString());
		}
		
		ProcessNode(*this, scene->mRootNode, scene, path);
	}
}
