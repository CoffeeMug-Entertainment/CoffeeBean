#ifndef CBE_INPUT_H
#define CBE_INPUT_H

#include "SDL_keycode.h"
#include <string>

namespace CBE
{

	void RegisterKey(std::string inputId, SDL_Keycode keycode);
	bool IsPressed(std::string inputId);
	void UpdateInput(SDL_Keycode keycode, bool pressed);
}

#endif