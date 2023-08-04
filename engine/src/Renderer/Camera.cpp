#include "Camera.h"

#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "App.h"
#include "SDL_opengl.h"

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
		int w,h;
		SDL_GL_GetDrawableSize(App::Instance().m_window, &w, &h);
		float aspect = static_cast<float>(w) / static_cast<float>(h);
		float fovy = fov / aspect;
		matrix = glm::perspective(glm::radians(fovy), aspect, 0.01f, 100.0f);
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
		rotation = {0.0f, 0.0f, 0.0f};
		target = {0.0f, 0.0f, 0.0f};
		up = {0.0f, 1.0f, 0.0f};
		right = {1.0f, 0.0f, 0.0f};
		forward = {0.0f, 0.0f, -1.0f};
		fov = 90.0f;

		/*
		right = glm::normalize(glm::cross(up, Direction()));
		up = glm::cross(Direction(), right);
		*/
	}
}
