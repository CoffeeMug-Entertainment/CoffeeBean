#ifndef CBE_COMPONENTS_H
#define CBE_COMPONENTS_H

#include "Renderer/Model.h"

#include "glm/vec3.hpp"
#include "glm/mat4x4.hpp"

namespace CBE
{
	struct TransformComp
	{
		glm::vec3 position;
		glm::vec3 rotation;
		glm::vec3 scale;

		glm::mat4 Identity();

		void ToDefault();
	};

	struct ModelComp
	{
		Model model;
	};
}

#endif
