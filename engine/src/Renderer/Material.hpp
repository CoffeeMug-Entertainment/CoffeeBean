#ifndef CBE_MATERIAL_HPP
#define CBE_MATERIAL_HPP

#include "glm/vec4.hpp"
#include "Texture.h"

namespace CBE
{
	struct Material
	{
		glm::vec4 ambient;
		glm::vec4 diffuse;
		glm::vec4 specular;
		float specular_exponent;
		float transparency;
		float refraction_exponent;
		Texture* ambient_map;
		Texture* diffuse_map;
	};

	extern Material MISSING_MAT;
}
#endif