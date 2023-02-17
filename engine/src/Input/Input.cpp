#include "Input.h"
#include "SDL_keycode.h"

#include <map>

namespace CBE 
{
	struct KeyBind
	{
		SDL_Keycode keycode;
		bool pressed;
	};

	std::map<std::string, CBE::KeyBind> g_registeredKeys;

	void RegisterKey(std::string inputId, SDL_Keycode keycode)
	{
		KeyBind k = {keycode, false};
		g_registeredKeys[inputId] = k;
	}

	bool IsPressed(std::string inputId)
	{
		if(!g_registeredKeys.contains(inputId)) return false;

		return g_registeredKeys[inputId].pressed;
	}

	void UpdateInput(SDL_Keycode keycode, bool pressed)
	{
		for(auto& [key, value] : g_registeredKeys)
		{
			if (value.keycode == keycode)
			{
				value.pressed = pressed;
			}
		}
	}
}