#include "Texture.h"
#include "stb_image.h"
#include "spdlog/spdlog.h"

namespace CBE
{
	Texture WHITE_PIXEL = {0, 1, 1, 4};
	unsigned char WHITE_PIXEL_DATA[1 * 1 * 4 + 1] = "\377\377\377\377";

	unsigned char* Texture::Load(std::string& filePath)
	{
		unsigned char* tex_data = stbi_load(filePath.c_str(), &width, &height, &comps, 0);
		if (!tex_data) 
		{
			spdlog::error("Failed to load {}\n\t Reason: {}", filePath, stbi_failure_reason());
			return nullptr;
  		}

		stbi_image_free(tex_data);
		return tex_data;
	}

	void Texture::PushToGPU(unsigned char* data)
	{
		glGenTextures(1, &id);
		glBindTexture(GL_TEXTURE_2D, id);

		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data);
	}

}
