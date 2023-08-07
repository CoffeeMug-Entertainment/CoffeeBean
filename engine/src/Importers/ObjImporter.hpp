#ifndef CBE_OBJIMPORTER_HPP
#define CBE_OBJIMPORTER_HPP

#include "Renderer/Mesh.h"

namespace CBE
{
	bool LoadMeshFromOBJ(std::string& filePath, Mesh& mesh);
}

#endif