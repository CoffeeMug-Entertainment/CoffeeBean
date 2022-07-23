#include "Components.h"
#include "glm/gtx/transform.hpp"
#include "glm/gtx/euler_angles.hpp"

namespace CBE
{
	glm::mat4 TransformComp::Matrix()
	{
		glm::mat4 transMatrix = glm::mat4(1.0f);
		transMatrix = glm::translate(transMatrix, position);
		transMatrix = glm::rotate(transMatrix, glm::radians(rotation.x), glm::vec3{1.0f, 0.0f, 0.0f});
		transMatrix = glm::rotate(transMatrix, glm::radians(rotation.y), glm::vec3{0.0f, 1.0f, 0.0f});
		transMatrix = glm::rotate(transMatrix, glm::radians(rotation.z), glm::vec3{0.0f, 0.0f, 1.0f});
		transMatrix = glm::scale(transMatrix, scale);
		return transMatrix;
	}

	void TransformComp::ToDefault()
	{
		position = {0.0f, 0.0f, 0.0f};
		rotation = {0.0f, 0.0f, 0.0f};
		scale = {1.0f, 1.0f, 1.0f};
	}
}
