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
		matrix = glm::lookAt(position, position + forward, up);
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

	void Camera::MouseLook(glm::vec2 mouseMovement, float deltaTime)
	{
		rotation.x -= mouseMovement.y * deltaTime;
		rotation.y += mouseMovement.x * deltaTime;
		rotation.x = std::clamp<float>(rotation.x, -89.0f, 89.0f);

		forward.x = cos(glm::radians(rotation.y)) * cos(glm::radians(rotation.x));
		forward.y = sin(glm::radians(rotation.x));
		forward.z = sin(glm::radians(rotation.y)) * cos(glm::radians(rotation.x));
		forward = glm::normalize(forward);

		right = glm::normalize(glm::cross(forward, glm::vec3{0.0f, 1.0f, 0.0f}));
		up = glm::normalize(glm::cross(right, forward));
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
