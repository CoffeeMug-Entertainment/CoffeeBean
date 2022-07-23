#include "Components.h"
#include "glm/gtx/transform.hpp"
#include "glm/gtx/euler_angles.hpp"

namespace CBE
{
	glm::mat4 TransformComp::Matrix()
	{
		glm::mat4 scaleMatrix = glm::scale(scale);
		glm::mat4 rotMatrix = glm::eulerAngleYXZ(rotation.y, rotation.x, rotation.z);
		glm::mat4 transMatrix = glm::translate(position);

		glm::mat4 identity = transMatrix + rotMatrix + scaleMatrix;
		return identity;
	}

	void TransformComp::ToDefault()
	{
		position = {0.0f, 0.0f, 0.0f};
		rotation = {0.0f, 0.0f, 0.0f};
		scale = {1.0f, 1.0f, 1.0f};
	}
}
