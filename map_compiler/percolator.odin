package percolator

import "libs:qmap"
import "core:log"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:strings"

output_filename : string
output_extension: string = ".cbm"
make_mars_3d : bool = false

print_usage :: #force_inline proc()
{
	fmt.printf("USAGE:\npercolator [ARGUMENTS] name_of_your.map\n")
}

main :: proc()
{
	// process args
	if len(os.args) < 2
	{
		print_usage()
		return
	}

	input_filename := os.args[len(os.args) - 1]
	if !os.exists(input_filename)
	{
		fmt.printfln("File %v does not exist!", input_filename)
		return
	}

	for arg, i in os.args
	{

		if strings.contains(arg, "--help") || strings.contains(arg, "-h")
		{
			print_usage()
			return
		}

		if strings.contains(arg, "-m3d")
		{
			make_mars_3d = true
			output_extension = ".m3d"
			continue
			//log.infof("Making Mars3D Scene")
		}

		if strings.contains(arg, "-o")
		{
			output_filename = os.args[i + 1]
		}
	}

	if output_filename == ""
	{
		split_path := strings.split(input_filename, "/", context.temp_allocator)
		file_name_w_extension := split_path[len(split_path) - 1]
		split_path = strings.split(file_name_w_extension, ".", context.temp_allocator)
		output_filename = fmt.tprint(split_path[0], output_extension, sep="")
	}

	
	

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
	
	doc, ok := qmap.load_from_file(input_filename)
	defer qmap.destroy(doc)

	flags := os.O_WRONLY | os.O_CREATE
	modes := os.S_IRUSR | os.S_IWUSR | os.S_IRGRP | os.S_IROTH
	output_file, file_err := os.open(output_filename, flags, modes)
	if file_err != os.ERROR_NONE
	{
		fmt.printfln("Could not open output_file %v", output_filename)
		return
	}

	defer os.close(output_file)

	for e in doc.entities
	{
		os.write_string(output_file, fmt.tprintln(e))
	}
	free_all(context.temp_allocator)
}