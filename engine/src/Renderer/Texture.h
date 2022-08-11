#ifndef CBE_TEXTURE_H
#define CBE_TEXTURE_H

#include "glad/glad.h"

#include <string>

namespace CBE 
{
	struct Texture
	{
		GLuint id;
		int width;
		int height;
		int comps;

		unsigned char* Load(std::string& filePath);

		void PushToGPU(unsigned char* data);
	};

	extern Texture WHITE_PIXEL;
	extern unsigned char WHITE_PIXEL_DATA[1 * 1 * 4 + 1];
}
#endif
