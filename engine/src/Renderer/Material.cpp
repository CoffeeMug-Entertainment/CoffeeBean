#include "Material.hpp"
#include "Renderer/Texture.h"

namespace CBE
{
	Material MISSING_MAT = Material
	{
		.ambient = glm::vec4{1.0f, 1.0f, 1.0f, 1.0f},
		.diffuse = glm::vec4{1.0f, 1.0f, 1.0f, 1.0f},
		.specular = glm::vec4{0.0f, 0.0f, 0.0f, 1.0f},
		.specular_exponent = 0.0f,
		.transparency = 0.0f,
		.refraction_exponent = 0.0f,
		.ambient_map = &WHITE_PIXEL,
		.diffuse_map = &MISSING_TEX
	};
}