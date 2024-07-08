package percolator

import "libs:qmap"
import "core:log"
import "core:mem"
import "core:fmt"

main :: proc()
{
	logger := log.create_console_logger()
	defer log.destroy_console_logger(logger)
	context.logger = logger

	when ODIN_DEBUG
	{
		tracking_allocator: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking_allocator, context.allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)

		defer 
		{
			for k, v in tracking_allocator.allocation_map
			{
				log.warnf("%v: Leaked %v bytes\n", v.location, v.size)
			}

			mem.tracking_allocator_clear(&tracking_allocator)
		} 
	}

	doc, ok := qmap.load_from_file("basegame/test.map")

	log.info("Printing entities")
	for e in doc.entities
	{
		fmt.println("\t", e)
	}
	

	qmap.destroy(doc)
}