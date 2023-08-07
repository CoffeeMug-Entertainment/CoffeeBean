#include "Model.h"
#include "Renderer/Mesh.h"
#include "Renderer/Texture.h"
#include "Shader.h"
#include "App.h"

#include "Importers/ObjImporter.hpp"
#include "assimp/Importer.hpp"
#include "assimp/scene.h"
#include "assimp/postprocess.h"
#include "stb_image.h"
#include "fmt/core.h"
#include <filesystem>

#define USE_ASSIMP 0

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

			newTex->Load(fullTexDirStr);
		}
		else
		{
			fmt::println("Model {} has no materials", path);
			newTex->width = MISSING_TEX.width;
			newTex->height = MISSING_TEX.height;
			newTex->comps = MISSING_TEX.comps;
			newTex->data = MISSING_TEX_DATA;
			newTex->PushToGPU();
			
		}

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
#if USE_ASSIMP < 1
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
#else
		Assimp::Importer importer;
		const aiScene* scene = importer.ReadFile(path, aiProcess_Triangulate | aiProcess_FlipUVs);

		if(!scene || scene->mFlags & AI_SCENE_FLAGS_INCOMPLETE || !scene->mRootNode)
		{
			fmt::print("Assimp failed to import file {}\n\tReason: {}", path, importer.GetErrorString());
		}
		
		ProcessNode(*this, scene->mRootNode, scene, path);
#endif
	}

}
