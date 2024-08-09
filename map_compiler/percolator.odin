package percolator

import "libs:qmap"
import "core:log"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/linalg"

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

	//NOTE(Fix): lmao
	context.allocator = context.temp_allocator

	if make_mars_3d
	{
		mars_scene : Mars3DScene
		for brush in doc.entities[0].brushes
		{
			mesh : Mars3DMesh
			mesh.local_transform = linalg.identity_matrix(type_of(mesh.local_transform))
			defer append(&mars_scene.objects, mesh)

			for poly in brush.polys
			{
				submesh: Mars3DSubmesh
				defer append(&mesh.submeshes, submesh)

				//TODO(Fix): No duplicate vertices, sort indices
				for vtx in poly.vertices
				{
					append(&mesh.vertices, vtx)
					append(&mesh.uvs, qmap.vec2{0, 0})
					append(&submesh.indices, u16(len(mesh.vertices) - 1))
				}
			}
		}

		str_builder : strings.Builder
		strings.builder_init(&str_builder)
		{
			strings.write_string(&str_builder, "Mars3DScene = \n{\n")
			defer strings.write_string(&str_builder, "\n}")
			strings.write_string(&str_builder, "Framerate = \"0\"\n")
			strings.write_string(&str_builder, "Objects = \n[\n")

			for object in mars_scene.objects
			{
				strings.write_string(&str_builder, "Mesh = \n{\n")
				defer strings.write_string(&str_builder, "\n}")
				strings.write_string(&str_builder, fmt.tprintf("Name = \"%v\"\n", object.name))
				strings.write_string(&str_builder, "LocalTransform = \"")
				//HACK(Fix): We can't iterate over a matrix, so i'm abusing Odin's fmt here
				{
					local_transform_output := fmt.tprint(object.local_transform)
					local_transform_output , _ = strings.remove_all(local_transform_output, ";")
					local_transform_output , _ = strings.remove_all(local_transform_output, ",")
					local_transform_output , _ = strings.remove_all(local_transform_output, "]")
					local_transform_output , _ = strings.remove_all(local_transform_output, "matrix[")
					strings.write_string(&str_builder, local_transform_output)
				}
				

				strings.write_string(&str_builder, "\"\n")
				strings.write_string(&str_builder, "Vertices = \n[\n")
				//zzz
				for vtx in object.vertices
				{
					strings.write_quoted_string(&str_builder, fmt.tprintf("%v, %v, %v", vtx.x, vtx.y, vtx.z))
					strings.write_rune(&str_builder, '\n')
				}
				strings.write_string(&str_builder, "]\n")

				strings.write_string(&str_builder, "UVs = \n[\n")
				for uv in object.uvs
				{
					strings.write_quoted_string(&str_builder, fmt.tprintf("%v, %v", uv.x, uv.y))
					strings.write_rune(&str_builder, '\n')
				}
				strings.write_string(&str_builder, "]\n")

				strings.write_string(&str_builder, "Submeshes = \n[\n")
				for submesh in object.submeshes
				{
					strings.write_string(&str_builder, "{\n")
					defer strings.write_string(&str_builder, "\n}\n")
					strings.write_string(&str_builder, fmt.tprintf("Material = \"%v\"\n", submesh.material))

					strings.write_string(&str_builder, "Indices = \n[\n")
					for index in submesh.indices
					{
						strings.write_quoted_string(&str_builder, fmt.tprint(index))
						strings.write_rune(&str_builder, '\n')
					}
					strings.write_string(&str_builder, "]\n")
				}
				strings.write_string(&str_builder, "]\n")
			}
			strings.write_string(&str_builder, "\n]\n")
		}
		os.write_string(output_file, strings.to_string(str_builder))
	}

	free_all(context.temp_allocator)
}



// M3D data for export
Mars3DScene :: struct
{
	framerate: uint,
	objects: [dynamic]Mars3DMesh,
}

Mars3DMesh :: struct
{
	name: string,
	local_transform: linalg.Matrix4x4f32,
	vertices: [dynamic]qmap.vec3,
	uvs: [dynamic]qmap.vec2,
	submeshes: [dynamic]Mars3DSubmesh,
}

Mars3DSubmesh :: struct
{
	material: string,
	indices: [dynamic]u16,
}