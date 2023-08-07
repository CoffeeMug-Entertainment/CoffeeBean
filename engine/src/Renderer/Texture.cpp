#include "Texture.h"
#include "stb_image.h"
#include "fmt/core.h"

namespace CBE
{
	unsigned char WHITE_PIXEL_DATA[1 * 1 * 4 + 1] = "\377\377\377\377";
	Texture WHITE_PIXEL = {0, 1, 1, 4, WHITE_PIXEL_DATA};
	
	unsigned char MISSING_TEX_DATA[2 * 2 * 4 + 1] = "\300\377\356\377K\037\016\377K\037\016\377\300\377\356\377";
	Texture MISSING_TEX = {0, 2, 2, 4, MISSING_TEX_DATA};

	bool Texture::Load(std::string& filePath)
	{
		unsigned char* tex_data = stbi_load(filePath.c_str(), &width, &height, &comps, 0);
		if (!tex_data) 
		{
			fmt::println("Failed to load texture: {}\n\t Reason: {}", filePath, stbi_failure_reason());
			this->width = MISSING_TEX.width;
			this->height = MISSING_TEX.height;
			this->comps = MISSING_TEX.comps;
			this->data = MISSING_TEX_DATA;
			return false;
		}

		this->data = tex_data;
		//stbi_image_free(tex_data);

		return true;
	}

	void Texture::PushToGPU()
	{
		glGenTextures(1, &id);
		glBindTexture(GL_TEXTURE_2D, id);

		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

		GLint gl_format;

		switch (comps) 
		{
			case 4:
				gl_format = GL_RGBA;
				break;
			case 3:
				gl_format = GL_RGB;
				break;
			default:
				fmt::println("Image format not yet implemented, assuming GL_RGB! comps: {}", comps);
				gl_format = GL_RGB;
				break;
		}

		glTexImage2D(GL_TEXTURE_2D, 0, gl_format, width, height, 0, gl_format, GL_UNSIGNED_BYTE, this->data);
		glGenerateMipmap(GL_TEXTURE_2D);
		glBindTexture(GL_TEXTURE_2D, 0);
	}

}
