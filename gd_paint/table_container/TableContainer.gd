tool
extends PanelContainer

var ready := true
onready var frame_container := $Grid/AxisX/Elements
onready var layer_container := $Grid/AxisY/Elements
onready var content_container := $Grid/Content


export var dimensions := Vector2.ONE setget set_dimensions
func set_dimensions(val):
	dimensions = val
	if ready:
		handle_elements()


func _ready():
	ready = true
	handle_elements()



func handle_elements():
	if get_child_count() == 0: return
	
	var j = -1
	for container in [frame_container, layer_container, content_container]:
		j += 1
		var label = ["frame", "layer", "content"][j]
		var d_count = [dimensions.x, dimensions.y, dimensions.x * dimensions.y][j] + 1
		var child_count = container.get_child_count()
		container.get_child(0).visible = false
		for i in range(1, max(d_count, child_count)):
			if i >= d_count:
				print(i)
				container.get_child(i).queue_free()
			elif i >= child_count:
				var element: Control = container.get_child(0).duplicate(7)
				element.visible = true
				element.connect("gui_input", self, "on_" + label + "_gui_input", [element])
				
				
#				element.connect("pressed", self, "on_check_pressed", [element, label])
				container.add_child(element)
	
	$Grid/Content.columns = dimensions.x 
	rect_size = Vector2.ONE


#func on_check_pressed(element, label):
#	if label == "content":
#		pass


func id_to_cell(id: int):
	id -= 1
	return Vector2(
		id % content_container.columns,
		id / int(content_container.columns)
	)

func cell_to_id(cell: Vector2):
	return cell.y * content_container.columns + cell.x


func on_content_gui_input(event: InputEvent, id):
	pass


func on_frame_gui_input(event: InputEvent, frame: CheckBox):
	on_layer_gui_input(event, frame)
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and !event.pressed:
		frame.pressed = !frame.pressed
		for content in content_container.get_children():
			var pos = id_to_cell(content.get_index())
			if pos.x == frame.get_index() - 1:
				content.pressed = frame.pressed
		frame.pressed = !frame.pressed

func on_layer_gui_input(event: InputEvent, layer):
	if event is InputEventMouseButton and !event.pressed:
		if event.button_index == BUTTON_RIGHT:
			$LayerRightClick.popup()
			$LayerRightClick.connect("index_pressed", self, "on_layer_right_click_pressed", [layer], 4)
			$LayerRightClick.rect_global_position = get_global_mouse_position() - Vector2.DOWN*12


func set_visible(val):
	.set_visible(val)
	if val:
		handle_elements()


func _on_NewFrame_pressed():
	dimensions.x += 1
	handle_elements()


func _on_NewLayer_pressed():
	dimensions.y += 1
	handle_elements()


func on_layer_right_click_pressed(index, layer):
	layer.queue_free()
	handle_elements()
	dimensions.y -= 1


func _on_TableContainer_resized():
#	return
	var parent = get_parent()
	if parent is Control:
		parent.rect_min_size = get_minimum_size()
