/* 
* Quake .map Parser
* Author: Filip Homolka / @fhomolka
* License: Public Domain or zlib
*
* Clean-room implementation of Quake (1) .map format
*
* Original spec by id Software
*
* Basic Usage:
* Get a  ^qmap.Map with
* doc, ok := qmap.load_from_file("name_of_your_map_file.map")
* When you're done using it, just call
* qmap.destroy(doc)
*
*/

package qmap

import "core:strings"
import "core:strconv"
import "core:os"
import "core:math/linalg"
vec3 :: linalg.Vector3f32
vec2 :: linalg.Vector2f32


EPSILON :: 0.001

Map :: struct
{
	entities: [dynamic]Entity,

	//tokens: [dynamic]Token
}

Entity :: struct
{
	fields: map[string]string,
	brushes: [dynamic]Brush,
}

Brush :: struct
{
	faces: [dynamic]Face,
	polys: [dynamic]Poly,
}

Face :: struct
{
	//Parsed from file
	p1: vec3,
	p2: vec3,
	p3: vec3,
	material: string,
	x_offset: f32,
	y_offset: f32,
	rotation: f32,
	x_scale: f32,
	y_scale: f32,

	//Calculated
	normal: vec3,
	distance: f32,
}

Poly :: struct
{
	vertices: [dynamic]vec3,
	indices: [dynamic]u16
}

TokenType :: enum
{
	NONE,
	KEY,
	STRING_VALUE,
	NUMBER,
	TEXT_VALUE,
	BLOCK_OPEN,
	BLOCK_CLOSE,
	PAREN_OPEN,
	PAREN_CLOSE,
	COMMENT,
}

Token :: struct
{
	type: TokenType,
	value: string,
}

import "core:fmt"

parse_string :: proc(str_data: string) -> (^Map, bool)
{
	tokens: [dynamic]Token
	defer delete(tokens)
	q_map := new(Map)


	lines := strings.split(str_data, "\n")
	defer delete(lines)

	for line in lines
	{
		//There's useful metadata in the comments, but we'll skip them for now
		if strings.has_prefix(line, "//") do continue

		if strings.has_prefix(line, "{")
		{
			token: Token
			token.type = .BLOCK_OPEN
			token.value = line
			append(&tokens, token)
		}
		else if strings.has_prefix(line, "}")
		{
			token: Token
			token.type = .BLOCK_CLOSE
			token.value = line
			append(&tokens, token)
		}
		else if strings.has_prefix(line, "\"")
		{
			quote_start := 0
			quote_end := 1
			for i := 1; i < len(line); i += 1
			{
				if line[i] == '\"'
				{
					quote_end = i + 1
					break
				}
			}

			key_token: Token
			key_token.type = .KEY
			key_token.value = line[quote_start:quote_end]

			quote_start = quote_end + 1
			quote_end = quote_start + 1
			for i := quote_end; i < len(line); i += 1
			{
				if line[i] == '\"'
				{
					quote_end = i + 1
					break
				}
			}
			value_token: Token
			value_token.type = .STRING_VALUE
			value_token.value = line[quote_start:quote_end]

			append(&tokens, key_token)
			append(&tokens, value_token)
		}
		else if strings.has_prefix(line, "(")
		{
			splitted := strings.split(line, " ")
			defer delete(splitted)

			token: Token

			token.value = splitted[0]
			token.type = .PAREN_OPEN
			append(&tokens, token)

			token.value = splitted[1]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[2]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[3]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[4]
			token.type = .PAREN_CLOSE
			append(&tokens, token)

			token.value = splitted[5]
			token.type = .PAREN_OPEN
			append(&tokens, token)

			token.value = splitted[6]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[7]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[8]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[9]
			token.type = .PAREN_CLOSE
			append(&tokens, token)

			token.value = splitted[10]
			token.type = .PAREN_OPEN
			append(&tokens, token)

			token.value = splitted[11]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[12]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[13]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[14]
			token.type = .PAREN_CLOSE
			append(&tokens, token)

			token.value = splitted[15]
			token.type = .TEXT_VALUE
			append(&tokens, token)

			token.value = splitted[16]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[17]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[18]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[19]
			token.type = .NUMBER
			append(&tokens, token)

			token.value = splitted[20]
			token.type = .NUMBER
			append(&tokens, token)

			//fmt.println(tokens)
		}
	}

	for i := 0; i < len(tokens); i += 1
	{
		token := &tokens[i]

		if token.type == .BLOCK_OPEN 
		{
			block_start := i
			block_end := block_start + 1

			nesting := 0
			for j := block_start; j < len(tokens); j += 1
			{
				sub_token := &tokens[j]
				if sub_token.type == .BLOCK_OPEN
				{
					nesting += 1
					continue
				}
				
				if sub_token.type == .BLOCK_CLOSE
				{
					nesting -= 1
					if nesting == 0
					{
						block_end = j + 1
						break;
					}
				}
			}

			token_slice := tokens[block_start + 1 : block_end - 1]
			//fmt.printf("token_slice\n\tstart: %v\n\tend: %v\n", token_slice[0], token_slice[len(token_slice) - 1])

			entity := process_entity(token_slice)
			append(&q_map.entities, entity)

			i = block_end - 1
		}
	}

	return q_map, true
}

process_entity :: proc(slice: []Token) -> Entity
{
	entity: Entity

	for i := 0; i < len(slice); i += 1
	{
		token := &slice[i]

		#partial switch token.type
		{
			case .KEY:
			{
				value_token := &slice[i + 1]
				entity.fields[token.value] = value_token.value

				i += 1
			}
			case .BLOCK_OPEN: //This is a brush
			{
				ofs := 0

				b_close := &slice[i + ofs]
				for b_close.type != .BLOCK_CLOSE
				{
					ofs += 1
					b_close = &slice[i + ofs]
				}
				ofs += 2 //BUG(Fix): What the hell? This should be a + 1 at max, why is it getting .BLOCK_Close before the last 5 numbers?

				brush_slice := slice[i + 1:ofs]
				//fmt.printf("Entity Brushes Slice: \n\t%v \n\t%v\n", brush_slice[0], brush_slice[len(brush_slice) - 1])
				brush := process_brush(brush_slice)

				append(&entity.brushes, brush)

				i += ofs
			}
			case: fmt.println("Did not process: ", token.type)
		}
	}

	for b, i in entity.brushes
	{
		brush := &entity.brushes[i]
		create_vertices(brush)
		sort_vertices(brush);

		for p, i in brush.polys
		{
			poly := &brush.polys[i]
			
			//Generate tri-fans, because that's the simplest
			for f in 1..<u16(len(poly.vertices) - 1)
			{
				append(&poly.indices, 0)
				append(&poly.indices, f)
				append(&poly.indices, f + 1)
			}	
		}
	}
	
	return entity
}

process_brush :: proc(slice: []Token) -> Brush
{
	brush: Brush

	for i := 0; i < len(slice); i += 1
	{
		token := &slice[i]

		#partial switch token.type
		{
			case .PAREN_OPEN:
			{
				face_slice := slice[i: i + 21]
				face := process_face(face_slice)

				append(&brush.faces, face)
				i += 20
			}
		}
	}
	return brush
}

process_face :: proc(slice: []Token) -> Face
{
	face: Face

	ok: bool
	face.p1.x, ok = strconv.parse_f32(slice[1].value)
	face.p1.y, ok = strconv.parse_f32(slice[2].value)
	face.p1.z, ok = strconv.parse_f32(slice[3].value)

	face.p2.x, ok = strconv.parse_f32(slice[6].value)
	face.p2.y, ok = strconv.parse_f32(slice[7].value)
	face.p2.z, ok = strconv.parse_f32(slice[8].value)

	face.p3.x, ok = strconv.parse_f32(slice[11].value)
	face.p3.y, ok = strconv.parse_f32(slice[12].value)
	face.p3.z, ok = strconv.parse_f32(slice[13].value)

	face.material = slice[15].value

	face.x_offset, ok = strconv.parse_f32(slice[16].value)
	face.y_offset, ok = strconv.parse_f32(slice[17].value)
	face.rotation, ok = strconv.parse_f32(slice[18].value)
	face.x_scale, ok = strconv.parse_f32(slice[19].value)
	face.y_scale, ok = strconv.parse_f32(slice[20].value)

	//Calculate unstored data
	face.normal = linalg.cross(face.p3 - face.p1, face.p2 - face.p1)
	face.normal = linalg.normalize(face.normal)

	face.distance = -linalg.dot(face.normal, face.p1)	

	return face
}

intersect_3faces :: proc(first, second, third: Face) -> (vec3, bool)
{
	denom := linalg.dot(first.normal, linalg.cross(second.normal, third.normal))

	if denom < EPSILON
	{
		return vec3{0, 0, 0}, false
	}

	vec := (linalg.cross(third.normal, second.normal) * first.distance - 
			(linalg.cross(third.normal, first.normal)) * second.distance - 
			(linalg.cross(first.normal, second.normal)) * third.distance) / denom

	return vec, true
}

create_vertices :: proc(brush: ^Brush)
{
	for i in 0..<len(brush.faces)
	{
		t_poly : Poly
		append(&brush.polys, t_poly)
		new_poly := &brush.polys[i]
		for j in 0..<len(brush.faces)
		{
			for k in 0..<len(brush.faces)
			{
				if i == j || i == k || j == k {continue}

				new_vtx, ok := intersect_3faces(brush.faces[i], brush.faces[j], brush.faces[k])
				if !ok {continue}
				invalid := false
				for m in 0..<len(brush.faces)
				{
					if linalg.dot(brush.faces[m].normal, new_vtx) + brush.faces[m].distance > EPSILON
					{
						invalid = true
						break
					}
				}

				if invalid {continue}

				//HACK(Fix): The real solution would be to check why they happen in the first place
				//TODO(Fix): Check why do duplicate vertices happen
				DUPLICATE_PROTECTION :: true
				when DUPLICATE_PROTECTION
				{
					duplicate := false
					for vtx in new_poly.vertices
					{
						if linalg.distance(new_vtx, vtx) > EPSILON {continue}

						duplicate = true
						break
					}

					if duplicate {continue}
				}
				
				append(&new_poly.vertices, new_vtx)
			}
		}
	}
}

sort_vertices :: proc(brush: ^Brush)
{
	for i in 0..<len(brush.polys)
	{
		poly := &brush.polys[i]
		center_vtx : vec3
		for vtx in brush.polys[i].vertices
		{
			center_vtx += vtx
		}
		center_vtx /= cast(f32)len(brush.polys[i].vertices)
		
		for v_idx in 0..<len(poly.vertices) - 2
		{
			vtx := poly.vertices[v_idx]
			a := linalg.normalize(vtx - center_vtx)

			//We would've done (brush.faces[i].normal + center_vtx) - center_vtx here, but that's stupid
			tri_plane_normal := linalg.cross(brush.faces[i].normal, a - center_vtx)
			tri_plane_normal = linalg.normalize(tri_plane_normal)
			tri_plane_distance := -linalg.dot(tri_plane_normal, a)

			smallest_angle : f32 = -1
			smallest_vtx_idx := -1

			for v_j in 0..<len(poly.vertices)
			{
				other_vtx := poly.vertices[v_j]
				distance_from_plane := linalg.dot(tri_plane_normal, other_vtx)

				if distance_from_plane < -EPSILON {continue} // < for CW, > for CCW

				b := poly.vertices[v_j] - center_vtx
				b = linalg.normalize(b)

				angle : f32 = linalg.dot(a, b)
				if angle > smallest_angle
				{
					smallest_angle = angle
					smallest_vtx_idx = v_j
				}
			}

			if smallest_vtx_idx == -1
			{
				fmt.println("Invalid polygon!")
				continue
			}

			poly.vertices[smallest_vtx_idx], poly.vertices[v_idx + 1] = poly.vertices[v_idx + 1], poly.vertices[smallest_vtx_idx]
		}
	}
}

load_from_file :: proc(path: string) -> (^Map, bool)
{
	data, ok := os.read_entire_file(path)
	defer delete(data)

	if !ok do return nil, false

	str_data := strings.clone(string(data))
	defer delete(str_data)

	return parse_string(str_data)
}

destroy :: proc(q_map: ^Map)
{
	if q_map == nil do return

	for entity in q_map.entities
	{
		delete(entity.fields)
		for brush in entity.brushes
		{
			delete(brush.faces)
			for poly in brush.polys
			{
				delete(poly.vertices)
				delete(poly.indices)
			}
			delete(brush.polys)
		}
		delete(entity.brushes)
	}
	delete(q_map.entities)

	free(q_map)
}