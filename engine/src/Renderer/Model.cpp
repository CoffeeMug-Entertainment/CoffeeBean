#include "Model.h"
#include "Shader.h"

namespace CBE
{
	void Model::Draw()
	{
		shaderProgram->Use();

		for (Mesh& mesh : meshes) 
		{
			mesh.vao.Bind();
			glDrawElements(GL_TRIANGLES, mesh.indices.size(), GL_UNSIGNED_INT, 0);
			mesh.vao.Unbind();
		}

		glUseProgram(0);
	}
}
