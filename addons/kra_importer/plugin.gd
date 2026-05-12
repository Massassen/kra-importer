@tool
extends EditorPlugin

const KraImportPlugin := preload("res://addons/kra_importer/kra_import_plugin.gd")

var import_plugin: EditorImportPlugin
var _sweeping := false

func _enter_tree() -> void:
	import_plugin = KraImportPlugin.new()
	add_import_plugin(import_plugin)
	
	var efs := EditorInterface.get_resource_filesystem()
	efs.filesystem_changed.connect(_on_filesystem_changed)
	
	# Sweep any ghosts left over from a previous session
	_sweep_autosave_ghosts("res://")

func _exit_tree() -> void:
	var efs := EditorInterface.get_resource_filesystem()
	if efs.filesystem_changed.is_connected(_on_filesystem_changed):
		efs.filesystem_changed.disconnect(_on_filesystem_changed)
	remove_import_plugin(import_plugin)
	import_plugin = null

func _on_filesystem_changed() -> void:
	if _sweeping:
		return
	_sweeping = true
	_sweep_autosave_ghosts("res://")
	_sweeping = false

func _sweep_autosave_ghosts(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	
	dir.include_hidden = true
	dir.list_dir_begin()
	
	var name := dir.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		
		if dir.current_is_dir():
			if name != "." and name != ".." \
			and not FileAccess.file_exists(full.path_join(".gdignore")):
				_sweep_autosave_ghosts(full)
		else:
			# Orphaned .import sidecar whose source autosave is gone
			if name.ends_with(".import") and name.begins_with(".") and "-autosave.kra" in name:
				var source := full.trim_suffix(".import")
				if not FileAccess.file_exists(source):
					DirAccess.remove_absolute(full)
					EditorInterface.get_resource_filesystem().update_file(source)
					EditorInterface.get_resource_filesystem().update_file(full)
		
		name = dir.get_next()
	
	dir.list_dir_end()
