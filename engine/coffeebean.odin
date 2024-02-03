package CBE

import SDL "vendor:sdl2"
import "core:slice"
import "core:log"

main :: proc()
{
	logger := log.create_console_logger()
	defer log.destroy_console_logger(logger)
	context.logger = logger

	if !app_init()
	{
		log.error("Init failed, reason:\n\t",SDL.GetError())
		return
	}
	defer app_shutdown()

	old_ticks := SDL.GetTicks();

	for g_app.running
	{
		ticks := SDL.GetTicks()
		delta_ticks := ticks - old_ticks
		g_app.delta_time = cast(f32)delta_ticks / 1000.0

		app_process_events()
		app_update()
		app_render()

		old_ticks = ticks

		delete(g_app.last_keyboard_state)
		g_app.last_keyboard_state = slice.clone(g_app.keyboard_state)
	}
}
