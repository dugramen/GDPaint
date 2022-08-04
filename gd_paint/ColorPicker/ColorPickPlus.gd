tool
extends VBoxContainer

export var color: Color = Color().from_hsv(0.0, 1.0, 0.0, 1.0)
var hue := 0.0
var saturation := 0.0
var value := 0.0
var alpha := 1.0

func _ready():
	set_color()

func set_hsva(col: Color):
	hue = col.h
	saturation = col.s
	value = col.v
	alpha = col.a

func set_color(val := color):
	val.h = clamp(hue, 0, 1)
	val.s = clamp(saturation, 0, 1)
	val.v = clamp(value, 0, 1)
	val.a = clamp(alpha, 0, 1)
	color = val
#	$Colors/Left.color = color
	$SliderSaturation.get_stylebox("slider").texture.gradient.colors[1] = Color().from_hsv(hue, 1.0, 1.0, 1.0)
	$SliderValue.get_stylebox("slider").texture.gradient.colors[1] = Color().from_hsv(hue, 1.0, 1.0, 1.0)
	$SliderAlpha.get_stylebox("slider").texture.gradient.colors[1] = Color().from_hsv(hue, saturation, value, 1.0)
	$ColorGraph.material.set_shader_param("hue_color", Color().from_hsv(hue, 1.0, 1.0))
	update()
	$SliderHue.value = hue
	$SliderSaturation.value = saturation
	$SliderValue.value = value
	$SliderAlpha.value = alpha


func _on_TextureRect_gui_input(event):
	var rect = $ColorGraph.get_rect()
	if event is InputEventMouse and event.button_mask in [BUTTON_MASK_LEFT, BUTTON_MASK_RIGHT]:
		event.position.x = clamp(event.position.x, rect.position.x + 1, rect.end.x)
		event.position.y = clamp(event.position.y, rect.position.y, rect.end.y-1)
		saturation = float(event.position.x) / rect.size.x
		value = 1 - float(event.position.y) / rect.size.y
		set_color()
		
		var id = 0 if event.button_mask == BUTTON_MASK_LEFT else 1
		$Colors.get_child(id).color = color


func _draw():
	var size = $ColorGraph.rect_size
	var x_vect = saturation * size.x * Vector2.RIGHT + $ColorGraph.rect_position
	var y_vect = (1-value) * size.y * Vector2.DOWN + $ColorGraph.rect_position
	
	draw_line(x_vect, x_vect + size.y*Vector2.DOWN, Color.white, 1.0)
	draw_line(y_vect, y_vect + size.x*Vector2.RIGHT, Color.white, 1.0)


func _on_SliderHue_value_changed(value):
	hue = value
	set_color()


func _on_SliderSaturation_value_changed(value):
	saturation = value
	set_color()


func _on_SliderValue_value_changed(val):
	value = val
	set_color()


func _on_SliderAlpha_value_changed(value):
	alpha = value
	set_color()


func _on_Left_gui_input(event):
	if event is InputEventMouseButton:
		color = $Colors/Left.color
		set_hsva($Colors/Left.color)
		set_color()
		
		$Colors/Left/Popup/ColorPicker.color = color
		if event.doubleclick:
			$Colors/Right/Popup.popup()


func _on_Right_gui_input(event):
	if event is InputEventMouseButton:
		color = $Colors/Right.color
		set_hsva($Colors/Right.color)
		set_color()
		
		$Colors/Right/Popup/ColorPicker.color = color
		if event.doubleclick:
			$Colors/Right/Popup.popup()


func _on_ColorPickPlus_gui_input(event):
	return
	if event is InputEventMouse:
		if event.button_mask == BUTTON_MASK_LEFT:
			$Colors/Left.color = color
		if event.button_mask == BUTTON_MASK_RIGHT:
			$Colors/Right.color = color


func _on_slider_gui_input(event, slider):
	if event is InputEventMouse:
		if event.button_mask == BUTTON_RIGHT:
			var node: Slider = get_node("Slider" + slider)
			var rect = node.get_rect()
			node.value = clamp(event.position.x, rect.position.x, rect.end.x) / rect.size.x
			node.emit_signal("value_changed", node.value)
		
		if event.button_mask == BUTTON_MASK_LEFT:
			$Colors/Left.color = color
		if event.button_mask == BUTTON_MASK_RIGHT:
			$Colors/Right.color = color
		
		
