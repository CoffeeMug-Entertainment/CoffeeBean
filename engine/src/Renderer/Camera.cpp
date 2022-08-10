#include "Camera.h"

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "spdlog/spdlog.h"

namespace CBE
{
	inline glm::vec3 Camera::Direction()
	{
		return glm::normalize(target - position);
	}

	glm::mat4 Camera::ViewMatrix()
	{
		glm::mat4 matrix;
		matrix = glm::lookAt(position, target, up);
		return matrix;
	}
	
	glm::mat4 Camera::ProjectionMatrix()
	{
		glm::mat4 matrix;
		matrix = glm::perspective(glm::radians(fov), 800.0f / 600.0f, 0.1f, 100.0f);
		return matrix;
	}

	void Camera::Move(glm::vec3 deltaPos)
	{
		position += deltaPos;
		target += deltaPos;
	}

	void Camera::ToDefault()
	{
		position = {0.0f, 0.0f, 1.0f};
		target = {0.0f, 0.0f, 0.0f};
		up = {0.0f, 1.0f, 0.0f};
		right = {1.0f, 0.0f, 0.0f};
		fov = 90.0f;

		/*
		right = glm::normalize(glm::cross(up, Direction()));
		up = glm::cross(Direction(), right);
		*/
	}
}
