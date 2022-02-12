tool
extends EditorPlugin


const MainPanel = preload("res://addons/gd_paint/Canvas/GDPaint.tscn")

var main_panel_instance
var inspector_plugin


func open_panel():
	if main_panel_instance:
		get_editor_interface().get_selection().clear()
		make_bottom_panel_item_visible(main_panel_instance)
		pass
#		get_editor_interface().set_main_screen_editor("GDPaint")


func load_sprite_pressed(path):
	open_panel()
	if main_panel_instance:
		main_panel_instance.load_sprite(path)


func _enter_tree():
	main_panel_instance = MainPanel.instance()
	main_panel_instance.plugin = self
	# Add the main panel to the editor's main viewport.
#	get_editor_interface().get_editor_viewport().add_child(main_panel_instance)
	add_control_to_bottom_panel(main_panel_instance, "GD Paint")
	
	
	inspector_plugin = preload("res://addons/gd_paint/inspector_plugin.gd").new()
	inspector_plugin.plugin = self
	add_inspector_plugin(inspector_plugin)
	
	# Hide the main panel. Very much required.
	make_visible(false)


func _exit_tree():
	remove_inspector_plugin(inspector_plugin)
	if main_panel_instance:
		remove_control_from_bottom_panel(main_panel_instance)
		main_panel_instance.queue_free()          
		


#func forward_canvas_gui_input(event):

#func handles(object):
##	if object is StreamTexture:
##		return true
#	return false
#
#
#func forward_canvas_gui_input(event):
#	if event is InputEventKey:
#		return true
#	return false



#func has_main_screen():
#	return true


func make_visible(visible):
	if main_panel_instance:
		main_panel_instance.visible = visible
		if visible:
			open_panel()


func get_plugin_name():
	return "GDPaint"


func get_plugin_icon():
	# Must return some kind of Texture for the icon.
	return get_editor_interface().get_base_control().get_icon("Node", "EditorIcons")
