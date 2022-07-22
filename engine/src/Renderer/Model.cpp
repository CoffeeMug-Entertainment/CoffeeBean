#include "Model.h"
#include "Shader.h"
#include "App.h"

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
}
