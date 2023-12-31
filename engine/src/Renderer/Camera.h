#ifndef CBE_CAMERA_H
#define CBE_CAMERA_H

#include "glm/vec3.hpp"
#include "glm/mat4x4.hpp"

namespace CBE
{
	struct Camera
	{
		glm::vec3 position;
		glm::vec3 rotation;
		glm::vec3 target;
		glm::vec3 up;
		glm::vec3 right;
		glm::vec3 forward;
		float fov;

		inline glm::vec3 Direction();
		glm::mat4 ViewMatrix();
		glm::mat4 ProjectionMatrix();
		
		void Move(glm::vec3 deltaPos);
		void MouseLook(glm::vec2 mouseMovement, float deltaTime);

		void ToDefault();
	};
}
#endif
