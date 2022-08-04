tool
extends VBoxContainer

export var accept_drag := true
export(NodePath) var target_path = null

export var text := "" setget set_text
export var pressed := false setget set_pressed

var plugin


var target: CanvasItem = null

onready var style: StyleBoxFlat = $Button.get_stylebox("normal")
onready var hover: StyleBoxFlat = $Button.get_stylebox("hover")
onready var button := get_child(0)

var hover_id = 0


func _ready():
#	yield(get_tree(), "idle_frame")
#	propagate_mouse_filter()


	if get_child_count() > 1:
		target = get_child(1)
	elif target_path && has_node(target_path):
		target = get_node(target_path)
	else:
		return
	
	set_text(name)
	set_pressed()


func _draw():
	if hover_id != 0:
		var ypos = 0
		if hover_id == 1:
			ypos += rect_size.y
		draw_line(Vector2(0, ypos), Vector2(rect_size.x, ypos), Color(1,1,1,1).darkened(.2), 8.0)


func set_plugin(val):
	plugin = val
	if plugin:
		var editor_settings = plugin.get_editor_interface().get_editor_settings()
		var base_color: Color = editor_settings.get_setting("interface/theme/base_color")
		style.bg_color = base_color
		hover.bg_color = base_color.darkened(.1)
	


func propagate_mouse_filter(val := 1):
	return
	propagate_call("set_mouse_filter", [val])


func set_text(val):
	text = val
	if !is_instance_valid(button): return
	button.text = "" + val

func set_pressed(val := pressed):
	pressed = val
	if !is_instance_valid(button): return
	button.pressed = val
	button.emit_signal("pressed", val)
	

func set_text_arrow():
	if !Engine.editor_hint:
		return
	if pressed:
		button.icon = get_icon("GuiTreeArrowDown", "EditorIcons")
#		$Button.text = $Button.text.replacen(" > ", " v ")
	else:
		button.icon = get_icon("GuiTreeArrowRight", "EditorIcons")
#		$Button.text = $Button.text.replacen(" v ", " > ")

func _on_FoldingButton_toggled(val):
	toggle(val)
#	if !is_instance_valid(target): return
#	target.visible = val
#	pressed = val
#	set_text_arrow()


func _on_FoldingButton_pressed(val = !target.visible):
	toggle(val)
#	if !is_instance_valid(target): return
#	target.visible = val
#	pressed = val
#	set_text_arrow()

func toggle(val):
	if !is_instance_valid(target): return
	target.visible = val
	pressed = val
	set_text_arrow()


func get_drag_data(position):
	if !accept_drag: return
	propagate_mouse_filter()
	var butt = Button.new()
	butt.text = $Button.text
	butt.rect_size = $Button.rect_size
	butt.add_stylebox_override("normal", style.duplicate())
	set_drag_preview(duplicate(0))
	return self


func set_hover(id):
	hover_id = id
	update()


func can_drop_data(position, data):
#	style.set_border_width_all(0)
	set_hover(0)
	propagate_mouse_filter()
	if data is Control and data.is_in_group("FoldingButton") and accept_drag:
#		print("hovering")
		if position.y >= rect_size.y/2.0:
#			style.border_width_bottom = 2
			set_hover(1)
		else:
#			style.border_width_top = 2
			set_hover(-1)
		return true
	else:
		return false


func drop_data(position: Vector2, data: Control):
#	style.set_border_width_all(0)
	set_hover(0)
	if data == self: return
	var stuff = target if target.get_parent() != self else null
	var parent = data.get_parent()
	
	parent.remove_child(data)
	if stuff:
		parent.remove_child(stuff)
	
	get_parent().add_child(data)
	data.owner = get_parent()
	
	var new_id = get_index()
	if position.y >= rect_size.y/2.0:
		new_id += 1
	
	get_parent().move_child(data, new_id)
	if stuff:
		get_parent().add_child_below_node(data, stuff)


func _on_FoldingButton_mouse_exited():
#	style.set_border_width_all(0)
	set_hover(0)
	

