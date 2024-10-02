package percolator

import "libs:qmap"
import "core:log"
import "core:mem"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:math/linalg"
import "core:math"

import stbi "vendor:stb/image"

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

	if !strings.contains(output_filename, ".")
	{
		output_filename = fmt.tprintf("%s%s", output_filename, output_extension)
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

	//TEMP(Fix): Calculate UVs
	// I couldn't put this in qmap, because I don't know how to calculate UVs without texture size
	{
		for brush in doc.entities[0].brushes
		{
			for poly, idx in brush.polys
			{
				poly := &brush.polys[idx]
				face := &brush.faces[idx]
				material := face.material
				if !strings.contains(material, "/")
				{
					temp_path := fmt.tprintf("./basegame/textures/%v.tga", material) //TODO(Fix): Not hardcoded gamepath
					face.material = strings.clone(temp_path)
				}

				material_width: i32
				material_height: i32
				material_bpp: i32
				decoded := stbi.info(fmt.ctprint(face.material), &material_width, &material_height, &material_bpp)
				if decoded != 1
				{
					log.errorf("Could not find material: %v\n", face.material)
					//HACK(Fix): Make assumptions since we don't have this info
					material_width = 128
					material_height = 128
				}

				dot_n_up := linalg.abs(linalg.dot(face.normal, qmap.vec3{0, 0, 1}))
				dot_n_rt := linalg.abs(linalg.dot(face.normal, qmap.vec3{0, 1, 0}))
				dot_n_fw := linalg.abs(linalg.dot(face.normal, qmap.vec3{1, 0, 0}))

				rad_rot := face.rotation * linalg.RAD_PER_DEG

				for vtx in poly.vertices
				{
					uv : qmap.vec2
					defer append(&poly.uvs, uv)

					if dot_n_up >= dot_n_rt && dot_n_up >= dot_n_fw
					{
						uv.x = vtx.x
						uv.y = -vtx.y
					}
					else if dot_n_rt >= dot_n_up && dot_n_rt >= dot_n_fw
					{
						uv.x = vtx.x
						uv.y = -vtx.z
					}
					else if dot_n_fw >= dot_n_up && dot_n_fw >= dot_n_rt
					{
						uv.x = vtx.y
						uv.y = -vtx.z
					}
					else
					{
						log.warnf("Somehow, normal (dot) u/r/f are all the same but also different. Hell has frozen over.")
					}

					rotated_uv : qmap.vec2
					rotated_uv.x = (uv.x * linalg.cos(rad_rot) - uv.y * linalg.sin(rad_rot))
					rotated_uv.y = (uv.x * linalg.sin(rad_rot) + uv.y * linalg.cos(rad_rot))
					uv = rotated_uv

					uv.x /= f32(material_width)
					uv.y /= f32(material_height)

					uv.x /= face.x_scale
					uv.y /= face.y_scale

					uv.x += face.x_offset / f32(material_width)
					uv.y += face.y_offset / f32(material_height)
				}
			}
		}
	}

	if make_mars_3d
	{
		mars_scene : Mars3DScene
		for brush in doc.entities[0].brushes
		{
			mesh : Mars3DMesh
			mesh.local_transform = linalg.identity_matrix(type_of(mesh.local_transform))
			defer append(&mars_scene.objects, mesh)

			for poly, poly_idx in brush.polys
			{
				submesh: Mars3DSubmesh
				defer append(&mesh.submeshes, submesh)
				submesh.material = brush.faces[poly_idx].material

				//TODO(Fix): No duplicate vertices, sort indices
				poly_vtxes: for vtx, poly_vtx_idx in poly.vertices
				{
					for mesh_vtx, mesh_vtx_idx in mesh.vertices
					{
						if linalg.distance(vtx, mesh_vtx) > qmap.EPSILON do continue

						continue poly_vtxes
					}
					
					append(&mesh.vertices, vtx)
					append(&mesh.uvs, poly.uvs[poly_vtx_idx])
					
				}

				for vtx_idx in poly.indices
				{
					poly_vtx := poly.vertices[vtx_idx]

					for mesh_vtx, mesh_vtx_idx in mesh.vertices
					{
						if linalg.distance(poly_vtx, mesh_vtx) > qmap.EPSILON do continue
						
						append(&submesh.indices, u16(mesh_vtx_idx))
						break
					}
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
				defer strings.write_string(&str_builder, "\n}\n\n")
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