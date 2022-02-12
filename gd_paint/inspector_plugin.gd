tool
extends EditorInspectorPlugin


var plugin
var edit_button = preload("res://addons/gd_paint/Inspector/EditTextureButton.tscn")
var path


func can_handle(object):
	# We support all objects in this example.
	if object is StreamTexture: 
		path = object.resource_path
		return true


func parse_end():
	var button: Button = edit_button.instance()
	
	if is_instance_valid(plugin):
		button.connect("pressed", plugin, "load_sprite_pressed", [path])
	
	add_custom_control(button)
