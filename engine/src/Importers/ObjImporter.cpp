#include "ObjImporter.hpp"
#include "Renderer/Mesh.h"
#include "Renderer/Material.hpp"
#include "Renderer/Texture.h"
#include "stb_image.h"
#include "fmt/core.h"
#include <fstream>
#include <iostream>
#include <sstream>
#include <filesystem>

namespace CBE
{
	const std::string MTL_AMBIENT = "Ka";
	const std::string MTL_DIFFUSE = "Kd";
	const std::string MTL_SPECULAR = "Ks";
	const std::string MTL_SPECULAR_EXP = "Ns";
	const std::string MTL_DISSOLVE = "d";
	const std::string MTL_TRANSPARENCY = "Tr";
	const std::string MTL_AMBIENT_MAP = "map_Ka";
	const std::string MTL_DIFFUSE_MAP = "map_Kd";
	const std::string MTL_COMMENT = "#";

	bool LoadMaterialFromMTL(std::filesystem::path mat_path, Material& material)
	{
		std::stringstream mtlStringStream;
		std::ifstream mtlFileStream(mat_path.string());
		std::string line;
		std::string mode;

		if(!mtlFileStream.is_open())
		{
			fmt::println("[MTL IMPORTER] Could not load MTL {}", mat_path.string());
			return false;
		}

		while (std::getline(mtlFileStream, line))
		{
			mtlStringStream.clear();
			mtlStringStream.str(line);
			mtlStringStream >> mode;

			if(mode == MTL_AMBIENT)
			{
				mtlStringStream >> material.ambient.r;
				mtlStringStream >> material.ambient.g;
				mtlStringStream >> material.ambient.b;
				material.ambient.a = 1.0f;
				continue;
			}
			else if (mode == MTL_DIFFUSE)
			{
				mtlStringStream >> material.diffuse.r;
				mtlStringStream >> material.diffuse.g;
				mtlStringStream >> material.diffuse.b;
				material.ambient.a = 1.0f;
				continue;
			}
			else if(mode == MTL_SPECULAR)
			{
				mtlStringStream >> material.specular.r;
				mtlStringStream >> material.specular.g;
				mtlStringStream >> material.specular.b;
				material.ambient.a = 1.0f;
				continue;
			}
			else if(mode == MTL_SPECULAR_EXP)
			{
				mtlStringStream >> material.specular_exponent;
				continue;
			}
			else if(mode == MTL_DISSOLVE)
			{
				float d;
				mtlStringStream >> d;
				material.transparency = 1.0f - d;
			}
			else if(mode == MTL_TRANSPARENCY)
			{
				mtlStringStream >> material.transparency;
			}
			else if(mode == MTL_AMBIENT_MAP)
			{
				material.ambient_map = new Texture();
				std::string ambient_map_path;
				mtlStringStream >> ambient_map_path;
				ambient_map_path = mat_path.parent_path().string() + "/" + ambient_map_path;
				material.ambient_map->Load(ambient_map_path);
				material.ambient_map->PushToGPU();
			}
			else if(mode == MTL_DIFFUSE_MAP)
			{
				material.diffuse_map = new Texture();
				std::string diffuse_map_path;
				mtlStringStream >> diffuse_map_path;
				diffuse_map_path = "./" + mat_path.parent_path().string() + "/" + diffuse_map_path;
				material.diffuse_map->Load(diffuse_map_path);
				material.diffuse_map->PushToGPU();
			}
			else if(mode == MTL_COMMENT)
			{
				continue;
			}
			else
			{
				fmt::println("[MTL IMPORTER] Mode {} not yet handled", mode);
			}
		}

		if(material.diffuse_map == nullptr)
		{
			material.diffuse_map = &MISSING_TEX;
		}

		return true;
	}

	const std::string OBJ_VERT = "v";
	const std::string OBJ_UV = "vt";
	const std::string OBJ_NORMAL = "vn";
	const std::string OBJ_FACE = "f";
	const std::string OBJ_MTLLIB = "mtllib";
	const std::string OBJ_COMMENT = "#";

	bool LoadMeshFromOBJ(std::filesystem::path obj_path, Mesh& mesh)
	{
		std::vector<int> vertexIndices;
		std::vector<int> uvIndices;
		std::vector<int> normalIndices;
		std::vector<glm::vec3> tempVertices;
		std::vector<glm::vec2> tempUVs;
		std::vector<glm::vec3> tempNormals;
		glm::vec3 tempVec3;
		glm::vec2 tempVec2;
		unsigned int tempUint = 0;
		Material* mat = nullptr;

		std::stringstream objStringStream;
		std::ifstream objFileStream(obj_path.string());
		std::string line;
		std::string mode;
		
		if (!objFileStream.is_open())
		{
			fmt::println("[OBJ IMPORTER]Could not load OBJ {}", obj_path.string());
			return false;
		}

		while (std::getline(objFileStream, line))
		{
			objStringStream.clear();
			objStringStream.str(line);
			objStringStream >> mode;

			if (mode == OBJ_VERT)
			{
				objStringStream >> tempVec3.x;
				objStringStream >> tempVec3.y;
				objStringStream >> tempVec3.z;
				tempVertices.emplace_back(tempVec3);
				continue;
			}
			else if(mode == OBJ_UV)
			{
				objStringStream >> tempVec2.x;
				objStringStream >> tempVec2.y;
				tempUVs.emplace_back(tempVec2);
				continue;
			}
			else if(mode == OBJ_NORMAL)
			{
				objStringStream >> tempVec3.x;
				objStringStream >> tempVec3.y;
				objStringStream >> tempVec3.z;
				tempNormals.emplace_back(tempVec3);
				continue;
			}
			else if(mode == OBJ_FACE)
			{
				int offset = 0;
				while (objStringStream >> tempUint)
				{
					switch (offset) 
					{
						case 0:
							vertexIndices.push_back(tempUint);
							break;
						case 1:
							uvIndices.push_back(tempUint);
							break;
						case 2:
							normalIndices.push_back(tempUint);
							break;
					}
					
					/*Indices come in 3 forms:
					* f v1 v2 v3
					* f v1/vt1/vn1 v2/vt2/vn2 v3/vt3/vn3
					*
					* This ensures we handled both of them.
					*/
					if (objStringStream.peek() == '/')
					{
						++offset;
						objStringStream.ignore(1, '/');
					}
					else if (objStringStream.peek() == ' ')
					{
						++offset;
						objStringStream.ignore(1, ' ');
					}

					if (offset > 2) offset = 0;
				}	
			}
			else if (mode == OBJ_MTLLIB)
			{
				// TODO(fhomolka)Only one material for now, handle multiple materials
				if(mat != nullptr) continue;

				mat = new Material();
				std::string relative_mat_path;
				std::string abs_mat_path;
				objStringStream >> relative_mat_path;

				abs_mat_path = obj_path.parent_path().string() + "/" + relative_mat_path;

				if(!LoadMaterialFromMTL(abs_mat_path, *mat))
				{
					fmt::println("Failed to load Material {}", abs_mat_path);
					delete mat;
					mat = &MISSING_MAT;
				}
			}
			else if(mode == OBJ_COMMENT)
			{
				continue;
			}
			else
			{
				fmt::println("[OBJ IMPORTER] Mode {} not handled yet!", mode);
			}
		}

		objFileStream.close();

		//TODO(fhomolka): OBJ seems to allow different v + vn combo. How do we deal with that?
		for(unsigned int i = 0; i < tempVertices.size(); ++i)
		{
			mesh.EmplaceVertex(tempVertices[i], tempNormals[i], tempUVs[i]);
		}
#if 0 //This is what seems to be done a lot of times, but still not quite right
		for (unsigned int i = 0; i < vertexIndices.size(); ++i)
		{
			//NOTE(fhomolka): already subtracted 1 when loading
			glm::vec3 pos = tempVertices[vertexIndices[i]];
			glm::vec2 uv = tempUVs[uvIndices[i]];
			glm::vec3 normal = tempNormals[normalIndices[i]];
			mesh.EmplaceVertex(pos, normal, uv);
			mesh.indices.emplace_back(i);
		}
#endif
		for(unsigned int i = 0; i < vertexIndices.size(); ++i)
		{
			//NOTE(fhomolka): Despite starting from 1, OBJ indices can be -1, which means "last vertex"
			unsigned int temp_index = vertexIndices[i] > 0 ? vertexIndices[i] : vertexIndices[vertexIndices.size() - 1];
			mesh.indices.emplace_back(temp_index - 1);
		}

		if(mat == nullptr)
		{
			fmt::println("Model {} has no material, applying default", obj_path.string());
			mat = &MISSING_MAT;
		}

		mesh.material = mat;

		return true;
	}

	bool LoadMeshFromOBJ(std::string& filePath, Mesh& mesh)
	{
		std::filesystem::path obj_path(filePath);
		return LoadMeshFromOBJ(obj_path, mesh);
	}
}