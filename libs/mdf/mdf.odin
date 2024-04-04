package mdf

/* 
* MDF Parser
* Author: Filip Homolka / @fhomolka
* License: public domain or zlib
*
* Clean-room implementation of Mars Data Format
*
* Original spec by Nick London
* https://wiki.ironworksgames.com/doku.php?id=mdf_file_format
*
* Basic Usage:
* Get a  ^mdf.Document with
* doc, ok := mdf.load_from_file("name_of_your_mdf_file.mdf")
* When you're done using it, just call
* mdf.destroy(doc)
*
* TODO:
*		- INHERIT keyword
*		- writer/exporter
*		- C bindings
*/

import "core:os"
import "core:strings"
import "core:fmt"

TokenType :: enum
{
	NONE,
	LABEL,
	VALUE,
	CHUNK_OPEN,
	CHUNK_CLOSE,
	ARRAY_OPEN,
	ARRAY_CLOSE,

	EQUALS,
}

TokenType_Set :: bit_set[TokenType]

TokenType_Elements: TokenType_Set : {.VALUE, .CHUNK_OPEN, .ARRAY_OPEN}

Token :: struct
{
	type: TokenType,
	value: string,
	line: u32,
}

Error :: enum
{
	NONE = 0,
	COULD_NOT_READ = 1,
	INVALID = 2,
	FAIL = 3,
}

Chunk :: struct
{
	name: string,
	properties: map[string]Element,
}

Value :: struct
{
	name: string,
	val: string,
}

Array :: struct
{
	name: string,
	properties: [dynamic]Element,
}

Element :: union
{
	Value,
	Chunk,
	Array,
}

Document :: struct
{
	tokens: [dynamic]Token,
	properties: [dynamic]Element,
}

print_expect_set :: proc(got: Token, expected: TokenType_Set)
{
	fmt.printf("Line {}: {} got {} expected {}\n", got.line, got.value, got.type, expected)
}

print_expect :: proc(got: Token, expected: TokenType)
{
	fmt.printf("Line {}: {} got {} expected {}\n", got.line, got.value, got.type, expected)
}

process_chunk :: proc(slice: []Token) -> (chunk: Chunk, ok: bool)
{
	//NOTE(fhomolka): 0 and 1 should be LABEL and EQUALS
	for i := 0; i < len(slice); i += 1
	{
		#partial switch slice[i].type
		{
			case .LABEL:
				if slice[i + 1].type != .EQUALS
				{
					print_expect(slice[i + 1], .EQUALS)
					return chunk, false
				}
				if slice[i + 2].type not_in TokenType_Elements
				{
					print_expect_set(slice[i + 2], TokenType_Elements)
					return chunk, false
				}

				ei := i + 2
				#partial switch slice[ei].type
				{
					case .VALUE:
						new_val: Value
						new_val.name = slice[i].value
						new_val.val = slice[i + 2].value
						chunk.properties[new_val.name] = new_val
						i = ei
					case .ARRAY_OPEN:
						nesting := 1
						closing_index := ei + 1
						for j := closing_index; j < len(slice); j += 1
						{
							if slice[j].type == .ARRAY_OPEN
							{
								nesting += 1
							}

							if slice[j].type == .ARRAY_CLOSE
							{
								nesting -= 1
							}

							if nesting < 1  
							{
								closing_index = j
								break
							}
						}

						sub_slice := slice[ei + 1:closing_index]
						array, ok := process_array(sub_slice)
						if !ok { return chunk, false}
						array.name = slice[i].value
						chunk.properties[array.name] = array
						i = closing_index
					case .CHUNK_OPEN:
						nesting := 1
						closing_index := ei + 1
						for j := closing_index; j < len(slice); j += 1
						{
							if slice[j].type == .CHUNK_OPEN
							{
								nesting += 1
							}

							if slice[j].type == .CHUNK_CLOSE
							{
								nesting -= 1
							}

							if nesting < 1  
							{
								closing_index = j
								break
							}
						}

						sub_slice := slice[ei + 1:closing_index]
						c, ok := process_chunk(sub_slice)
						if !ok { return chunk, false }
						c.name = slice[i].value
						chunk.properties[c.name] = c
						i = closing_index
				}
		}
	}

	return chunk, true
}

process_array :: proc(slice: []Token) -> (array: Array, ok: bool)
{
	if len(slice) < 1
	{
		return array, true
	}

	if slice[0].type not_in TokenType_Elements && slice[0].type != .LABEL
	{
		return array, false
	}

	for i := 0; i < len(slice); i += 1
	{
		#partial switch slice[i].type
		{
			case .LABEL:
				if slice[i + 1].type != .EQUALS
				{
					print_expect(slice[i + 1], .EQUALS)
					return array, false
				}
				if slice[i + 2].type not_in TokenType_Elements
				{
					print_expect_set(slice[i + 2], TokenType_Elements)
					return array, false
				}

				ei := i + 2
				#partial switch slice[ei].type
				{
					case .VALUE:
						new_val: Value
						new_val.name = slice[i].value
						new_val.val = slice[i + 2].value
						append(&array.properties, new_val)
						i = ei
					case .CHUNK_OPEN:
						nesting := 1
						closing_index := ei + 1
						for j := closing_index; j < len(slice); j += 1
						{
							if slice[j].type == .CHUNK_OPEN
							{
								nesting += 1
							}

							if slice[j].type == .CHUNK_CLOSE
							{
								nesting -= 1
							}

							if nesting < 1  
							{
								closing_index = j
								break
							}
						}

						sub_slice := slice[ei + 1:closing_index]
						chunk, ok := process_chunk(sub_slice)
						if !ok {return array, false}
						chunk.name = slice[i].value
						append(&array.properties, chunk)
						i = closing_index
					case .ARRAY_OPEN:
						nesting := 1
						closing_index := ei + 1
						for j := ei + 1; j < len(slice); j += 1
						{
							if slice[j].type == .ARRAY_OPEN
							{
								nesting += 1
							}

							if slice[j].type == .ARRAY_CLOSE
							{
								nesting -= 1
							}

							if nesting < 1  
							{
								closing_index = j
								break
							}
						}
						sub_slice := slice[ei + 1:closing_index]
						arr, ok := process_array(sub_slice)
						if !ok {return arr, false}
						arr.name = slice[i].value
						append(&array.properties, arr)
						i = closing_index
				}
			case .VALUE: //Anon value
				new_val: Value
				//new_val.name = ""
				new_val.val = slice[i].value
				append(&array.properties, new_val)
			case .CHUNK_OPEN: //Anon Chunk
				nesting := 1
				closing_index := i + 1
				for j := closing_index; j < len(slice); j += 1
				{
					if slice[j].type == .CHUNK_OPEN
					{
						nesting += 1
					}

					if slice[j].type == .CHUNK_CLOSE
					{
						nesting -= 1
					}

					if nesting < 1  
					{
						closing_index = j
						break
					}
				}

				sub_slice := slice[i + 1:closing_index]
				chunk, ok := process_chunk(sub_slice)
				if !ok {return array, false}
				append(&array.properties, chunk)
				i = closing_index
			case .ARRAY_OPEN: //Anon Chunks
				nesting := 1
				closing_index := i + 1
				for j := closing_index; j < len(slice); j += 1
				{
					if slice[j].type == .ARRAY_OPEN
					{
						nesting += 1
					}

					if slice[j].type == .ARRAY_CLOSE
					{
						nesting -= 1
					}

					if nesting < 1  
					{
						closing_index = j
						break
					}
				}
				sub_slice := slice[i + 1:closing_index]
				arr, ok := process_array(sub_slice)
				if !ok {return array, false }
				//arr.name = ""
				append(&array.properties, arr)
				i = closing_index
			case:
		}
	}
	

	return array, true
}

parse_string :: proc(data: string) -> (doc: ^Document, err: Error)
{
	doc = new(Document)
	local_data := data

	line_num: u32 = 1
	inside_array: bool = false
	expecting_node_or_array: bool = false

	// Tokenise
	for line in strings.split_lines_iterator(&local_data) 
	{
		trimmed_line := strings.trim_space(line)
		toks := strings.split(trimmed_line, " ")

		x := 0
		for ; x < len(toks); x += 1
		{
			tok := toks[x]
			token: Token

			token.value = tok
			token.line = line_num

			switch tok
			{
				case "{":
					token.type = .CHUNK_OPEN
				case "}":
					token.type = .CHUNK_CLOSE
				case "[":
					token.type = .ARRAY_OPEN
				case "]":
					token.type = .ARRAY_CLOSE
				case "=":
					token.type = .EQUALS
				case "":
					continue
				case "\"\"":
					token.type = .VALUE
				case: //BUG(fhomolka): There's a bug here, which cannot handle several values in the same line
					if(strings.contains(tok, "\""))
					{
						token.type = .VALUE

						full_value: string

						op := strings.index(trimmed_line, "\"")
						cl := op + 1
						for ; cl < len(trimmed_line); cl += 1
						{
							if strings.count(trimmed_line[op:cl + 1], "\"") != 2 { continue }
							full_value = trimmed_line[op:cl + 1]
							break
						}

						token.value = full_value[1:len(full_value)-1]

						f := x + 1
						for ; f < len(toks); f += 1 //Progress the token index
						{
							if !strings.contains(toks[f], "\"") { continue }
							x = f
							break
						}

						//delete(full_value)
						break
					}
					
					token.type = .LABEL
			}

			append(&doc.tokens, token)
		}
		delete(toks)
		line_num += 1
	}

	// Populate
	for i := 0; i < len(doc.tokens); i += 1
	{

		#partial switch doc.tokens[i].type
		{
			case .LABEL:
				if doc.tokens[i + 1].type != .EQUALS
				{
					print_expect(doc.tokens[i + 1], .EQUALS)
					return doc, .INVALID
				}
				if doc.tokens[i + 2].type not_in TokenType_Elements
				{
					print_expect_set(doc.tokens[i + 1], TokenType_Elements)
					return doc, .INVALID
				}

				ei := i + 2
				#partial switch doc.tokens[ei].type
				{
					case .VALUE:
						new_val: Value
						new_val.name = doc.tokens[i].value
						new_val.val = doc.tokens[ei].value
						append(&doc.properties, new_val)
						i = ei
					case .CHUNK_OPEN:
						nesting := 1
						closing_index := ei + 1
						for j := closing_index; j < len(doc.tokens); j += 1
						{
							if doc.tokens[j].type == .CHUNK_OPEN
							{
								nesting += 1
							}

							if doc.tokens[j].type == .CHUNK_CLOSE
							{
								nesting -= 1
							}

							if nesting < 1  
							{
								closing_index = j
								break
							}
						}

						slice := doc.tokens[ei:closing_index]
						new_chunk, ok := process_chunk(slice)
						if !ok {return doc, .FAIL}
						new_chunk.name = doc.tokens[i].value
						append(&doc.properties, new_chunk)
						i = closing_index
					case .ARRAY_OPEN:
						nesting := 1
						closing_index := ei + 1
						for j := closing_index; j < len(doc.tokens); j += 1
						{
							if doc.tokens[j].type == .ARRAY_OPEN
							{
								nesting += 1
							}

							if doc.tokens[j].type == .ARRAY_CLOSE
							{
								nesting -= 1
							}

							if nesting < 1  
							{
								closing_index = j
								break
							}
						}

						slice := doc.tokens[ei:closing_index]
						new_arr, ok := process_array(slice)
						if !ok {return doc, .FAIL}
						append(&doc.properties, new_arr)
						i = closing_index
				}
			case:
		}
	}
	return doc, .NONE
}

load_from_file :: proc(filename: string) -> (doc: ^Document, err: Error)
{
	data, ok := os.read_entire_file(filename)
	defer delete(data)

	if !ok {return {}, .COULD_NOT_READ}

	str_data := strings.clone(string(data))

	return parse_string(str_data)
}

destroy_element :: proc(element: ^Element)
{
	switch e in element
	{
		case Value: //It only holds text, which we will free later
		case Array:
			for i in 0..<len(e.properties) { destroy_element(&e.properties[i]) }
			delete(e.properties)
		case Chunk:
			for k, v in e.properties { destroy_element(&e.properties[k]) }
			delete(e.properties)
	}
}

destroy :: proc(doc: ^Document)
{
	if doc == nil { return }
	for i in 0..<len(doc.properties)
	{
		destroy_element(&doc.properties[i])
	}
	delete(doc.properties)

	if len(doc.tokens) > 0 {delete(doc.tokens[0].value)}
	
	delete(doc.tokens)
	free(doc)
}


// TODO(fhomolka): Type_Info support