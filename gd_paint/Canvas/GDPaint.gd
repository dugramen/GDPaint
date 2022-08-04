tool
extends Control

var plugin

onready var canvas: TextureRect = $TextureRect
#onready var item_list := $HBoxContainer/PanelContainer/VBoxContainer/ItemList
var undo_redo: UndoRedo

var is_hovering := false
var frame_done = false

export var panel_style: StyleBoxFlat

#func _ready():
#	print(Vector2(3,5) * Vector2(1, 6))

func _ready():
	Input.set_use_accumulated_input(true)
	$MarginContainer/HBoxContainer/PanelContainer/VBoxContainer.connect("resized", self, "_on_VBoxContainer_resized", [], 4)
	
	if plugin:
		var b_col: Color = plugin.get_editor_interface().get_editor_settings().get_setting("interface/theme/base_color")
		panel_style.bg_color = b_col.darkened(.25)
#		panel_style.border_color = b_col.darkened(0.0)
		propagate_call("set_plugin", [plugin])
	
	propagate_call("_set_host", [self])


func load_sprite(path):
	print("loading")
	$TextureRect.load_sprite(path)

#func _draw():
#	var pos = $TextureRect.get_canvas_center() - rect_global_position
#	draw_circle(pos, 4.0, Color.white)

func _gui_input(event):
	var check = true
#	if event is InputEventMouseMotion and !frame_done:
#		check = false
	if is_hovering and check:
		frame_done = true
		propagate_call("gui_input", [event.duplicate()])
#		$TextureRect.gui_input(event.duplicate())
		accept_event()
		
#		yield(get_tree(), "idle_frame")
#		frame_done = false


#func _physics_process(delta):
#	frame_done = false


func _input(raw_event):
	handle_size()
#	update()
	if is_hovering:
		var event = raw_event.duplicate()
		if raw_event is InputEventMouse:
			event.position = raw_event.position - rect_position
		propagate_call("_gdpaint_input", [event])
#		accept_event()


func _on_GDPaint_mouse_entered():
	grab_focus()
	is_hovering = true


func _on_GDPaint_mouse_exited():
	is_hovering = false


func can_drop_data(position, data):
	return data is Control and data.is_in_group("FoldingButton") and data.accept_drag


func drop_data(position, data: Control):
	var panel = $TextureRect.Left_panel
	if position.x > rect_size.x/2.0:
		panel = $TextureRect.Right_panel
#	var stuff = data.get_parent().get_child(data.get_index() + 1)
	data.get_parent().remove_child(data)
#	stuff.get_parent().remove_child(stuff)
	
	panel.add_child(data)
	data.owner = self
#	panel.add_child(stuff)
#	stuff.owner = self
	

func handle_size():
#	rect_min_size = $HBoxContainer.get_minimum_size()
	pass
	


func _on_HBoxContainer_resized():
	handle_size()
#	rect_min_size = $HBoxContainer.get_minimum_size()
	pass


func _on_GDPaint_resized():
	handle_size()
#	rect_min_size = $HBoxContainer.get_minimum_size()
	pass # Replace with function body.


func _on_VBoxContainer_resized():
#	print("smap")
	rect_min_size = $MarginContainer/HBoxContainer/PanelContainer/VBoxContainer.get_minimum_size() + Vector2.DOWN * 4
	$TextureRect.recenter_image()
