#include "ObjImporter.hpp"
#include "Renderer/Mesh.h"
#include "fmt/core.h"
#include <fstream>
#include <iostream>
#include <sstream>

namespace CBE
{
	const std::string OBJ_VERT = "v";
	const std::string OBJ_UV = "vt";
	const std::string OBJ_NORMAL = "vn";
	const std::string OBJ_FACE = "f";

	bool LoadMeshFromOBJ(std::string& filePath, Mesh& mesh)
	{
		std::vector<unsigned int> vertexIndices;
		std::vector<unsigned int> uvIndices;
		std::vector<unsigned int> normalIndices;
		std::vector<glm::vec3> tempVertices;
		std::vector<glm::vec2> tempUVs;
		std::vector<glm::vec3> tempNormals;
		glm::vec3 tempVec3;
		glm::vec2 tempVec2;
		unsigned int tempUint = 0;

		std::stringstream objStringStream;
		std::ifstream objFileStream(filePath);
		std::string line;
		std::string mode;
		
		if (!objFileStream.is_open())
		{
			fmt::println("Could not load OBJ {}", filePath);
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
							vertexIndices.push_back(tempUint - 1);
							break;
						case 1:
							uvIndices.push_back(tempUint - 1);
							break;
						case 2:
							normalIndices.push_back(tempUint - 1);
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
		}

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
		mesh.indices = vertexIndices;

		return true;
	}
}