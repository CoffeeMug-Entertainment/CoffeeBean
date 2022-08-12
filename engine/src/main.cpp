#include <iostream>
#include "App.h"

int main(int argc, char* argv[]) {
	//TEMP(fhomolka): Until we actually do something with them, silence unused warnings
	(void)argc;
	(void)argv;
	CBE::App game;
	game.Loop();
	return 0;
}
