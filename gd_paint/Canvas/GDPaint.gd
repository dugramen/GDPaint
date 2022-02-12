tool
extends MarginContainer

var plugin: EditorPlugin

onready var canvas: TextureRect = $TextureRect
onready var item_list := $HBoxContainer/PanelContainer/VBoxContainer/ItemList
var undo_redo: UndoRedo


func _ready():
#	propagate_call("set_plugin", [plugin])
	pass

func load_sprite(path):
	print("loading")
	$TextureRect.load_sprite(path)

#func _clips_input():
#	return false

#func _unhandled_input(event):
#	if get_global_rect().has_point(get_global_mouse_position()):
#		get_tree().set_input_as_handled()
#	pass

func _gui_input(event):
	propagate_call("gui_input", [event.duplicate()])
	accept_event()

#func _gui_input(event):
#	var ev = event.duplicate()
#	get_tree().set_input_as_handled()
#	propagate_call("_gui_input", [ev])
	


func _on_GDPaint_mouse_entered():
	grab_focus()
#	$TextureRect.mouse_filter = Control.MOUSE_FILTER_PASS
#	print('in')


func _on_GDPaint_mouse_exited():
	pass
#	$TextureRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	print('out')
