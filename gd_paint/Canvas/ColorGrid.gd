tool
extends GridContainer

onready var picker_left: ColorPickerButton = get_parent().get_node("HBoxContainer/ColorPickerButtonLeft")
onready var picker_right: ColorPickerButton = get_parent().get_node("HBoxContainer/ColorPickerButtonRight")


var palette := [
	Color(0,0,0,0), Color.white, Color.black, 
	Color.red, Color.orange, Color.yellow,
	Color.yellowgreen, Color.green, Color.cyan,
	Color.blue, Color.purple, Color.violet
]


func _ready():
	get_child(0).visible = false
	set_palette()
#	for color in palette:
#		add_color(color)


func set_palette(color_list := palette):
	palette = color_list
	for child in get_children():
		if child != $PaletteColor:
			child.queue_free()
	for col in color_list:
		add_color(col)


func _on_ColorPickerButtonLeft_popup_closed():
	var colors = picker_left.get_picker().get_presets()
#	palette.append(colors)
	for color in colors:
		picker_left.get_picker().erase_preset(color)
		add_color(color)


func add_color(color: Color):
	var button: ColorRect = $PaletteColor.duplicate()
	button.color = color
	button.visible = true
	button.connect("gui_input", self, "on_palette_color_pressed", [button])
	call_deferred("add_child", button)
	button.call_deferred("set_owner", self)


func on_palette_color_pressed(event: InputEvent, button: ColorRect):
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == BUTTON_LEFT:
				picker_left.color = button.color
				picker_left.emit_signal("color_changed", button.color)
			if event.button_index == BUTTON_RIGHT:
				picker_right.color = button.color
				picker_right.emit_signal("color_changed", button.color)
		if event.doubleclick:
			pass
	


func _on_Palette_item_rect_changed():
	pass # Replace with function body.
