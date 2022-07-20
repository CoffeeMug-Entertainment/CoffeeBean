#ifndef CBE_MODEL_H
#define CBE_MODEL_H

#include "Mesh.h"
#include "Shader.h"

namespace CBE
{
	struct Model
	{
		std::vector<Mesh> meshes;
		ShaderProgram* shaderProgram;
		
		void Draw();
	};
}

#endif
