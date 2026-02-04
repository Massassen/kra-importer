@tool
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "kra.texture.importer"

func _get_visible_name() -> String:
	return "Krita Texture"

func _get_recognized_extensions() -> PackedStringArray:
	return ["kra", "krz"]

func _get_save_extension() -> String:
	# Has to be "res" for PortableCompressedTexture2D
	return "res"

func _get_resource_type() -> String:
	# PortableCompressedTexture2D, not Texture2D or ImageTexture
	return "PortableCompressedTexture2D"

func _get_priority() -> float:
	return 1.0

func _get_import_order() -> int:
	return 0

func _get_preset_count() -> int:
	return 1

func _get_preset_name(preset_index: int) -> String:
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	return [
		{
			"name": "compress/mode",
			"default_value": 0,
			"property_hint": PROPERTY_HINT_ENUM,
			"hint_string": "Lossless:0,Lossy:1,Basis Universal:2,S3TC:3,BPTC:5"
		},
		{
			"name": "mipmaps/generate",
			"default_value": false
		},
		{
			"name": "process/premult_alpha",
			"default_value": false
		}
	]

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary, 
			 platform_variants: Array[String], gen_files: Array[String]) -> Error:
	
	# KRA files are just ZIP archives with a mergedimage.png inside
	var image := _extract_merged_image_from_kra(source_file)
	if image == null:
		push_error("Failed to extract image from %s - make sure it's a valid Krita file" % source_file)
		return ERR_FILE_CORRUPT
	
	# Validate we got actual image data
	if image.get_size() == Vector2i.ZERO:
		push_error("Image extracted from %s has zero size" % source_file)
		return ERR_FILE_CORRUPT
	
	# Apply premultiply alpha if requested
	if options.get("process/premult_alpha", false):
		image.premultiply_alpha()
	
	# Generate mipmaps before compression
	if options.get("mipmaps/generate", false):
		image.generate_mipmaps()
	
	var texture := PortableCompressedTexture2D.new()
	
	# Need to set this before create_from_image for proper re-importing
	texture.keep_compressed_buffer = true
	
	var compression_mode: int = options.get("compress/mode", 0)
	texture.create_from_image(image, compression_mode)
	
	var filename := "%s.%s" % [save_path, _get_save_extension()]
	var result := ResourceSaver.save(texture, filename)
	
	if result != OK:
		push_error("Failed to save texture to %s" % filename)
	
	return result

func _extract_merged_image_from_kra(kra_path: String) -> Image:
	var reader := ZIPReader.new()
	var err := reader.open(kra_path)
	
	if err != OK:
		push_error("Cannot open KRA archive: %s (error %d)" % [kra_path, err])
		return null
	
	# Krita always stores a flattened PNG as mergedimage.png
	var png_data := reader.read_file("mergedimage.png")
	reader.close()
	
	if png_data.is_empty():
		push_error("mergedimage.png not found in %s" % kra_path)
		return null
	
	var image := Image.new()
	err = image.load_png_from_buffer(png_data)
	
	if err != OK:
		push_error("Failed to decode PNG from %s" % kra_path)
		return null
	
	return image
