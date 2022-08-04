tool
extends PanelContainer

signal layer_added
signal frame_added
signal layer_removed(id)
signal frame_removed(id)
signal layer_moved(source, destination)
signal frame_moved(source, destination)

signal visibility_pressed
signal frame_selected
signal anim_frame_changed(frame)


onready var Layer_container := $VBox/HSplit/ScrollLayer/Layers
onready var Frame_container := $VBox/HSplit/ScrollFrame/Frames

onready var Animator_play := $VBox/Header/Animator/Play
onready var Animator_loop := $VBox/Header/Animator/Loop
onready var Animator_framerate := $VBox/Header/Animator/Framerate

onready var Scroll_layer := $VBox/HSplit/ScrollLayer
onready var Scroll_frame := $VBox/HSplit/ScrollFrame

onready var base_layer := Layer_container.get_child(0)
onready var base_frame := Frame_container.get_child(0)


var selected_layer := 0 setget set_selected_layer, get_selected_layer
var selected_frame := 0 setget set_selected_frame, get_selected_frame

var anim_frame := 0.0
var anim_frame_prev := 0.0


func _ready():
	connect_gui_element(Frame_container.get_child(0), "_on_Frame_gui_input")
	connect_gui_element(Layer_container.get_child(0), "_on_Layer_gui_input")
	yield(get_tree(), "idle_frame")
	set_selected_frame()
	set_selected_layer()
#	yield(get_tree(), "idle_frame")
	_on_Table_resized()

func get_fps():
	return Animator_framerate.value

func get_selected_layer():
#	print("selected layer is ", selected_layer, ", but layer count is ", Layer_container.get_child_count())
	return selected_layer

func get_selected_frame():
	return selected_frame


func set_selected_layer(val := selected_layer):
	val = clamp(val, 0, Layer_container.get_child_count() - 1)
	selected_layer = val
	for layer in Layer_container.get_children():
		layer.get_node("Selector").visible = layer.get_index() == val
		
func set_selected_frame(val := selected_frame):
	val = clamp(val, 0, Frame_container.get_child_count() - 1)
	selected_frame = val
	for frame in Frame_container.get_children():
		frame.get_child(0).pressed = frame.get_index() == val
	emit_signal("frame_selected")

func get_layer_visible(layer := selected_layer):
#	print(Frame_container.get_children())
#	print(Layer_container.get_children())
	if Layer_container:
		return Layer_container.get_child(layer).get_node("Visible").pressed
	else:
		return true

func connect_gui_element(element: Control, method):
	element.connect("gui_input", self, method, [element])


func resize_layer_icons():
	for layer in Layer_container.get_children():
		layer.get_node("Icon").rect_min_size.y = layer.get_node("Icon").rect_size.x


func _on_Layer_resized():
	if !Scroll_layer: return
	Scroll_layer.rect_min_size = Layer_container.get_child(0).get_minimum_size()

func get_layer_count():
	return Layer_container.get_child_count()

func get_frame_count():
	return Frame_container.get_child_count()

func add_layer():
	var layer := base_layer.duplicate()
	connect_gui_element(layer, "_on_Layer_gui_input")
	Layer_container.add_child(layer)
	set_selected_layer()

func _on_AddLayer_pressed():
	add_layer()
	var parent = get_parent()
	if parent is SplitContainer:
		var item_sep = Layer_container.get_constant("separation") * 2 + 2
#		print(item_sep)
		var item_height = Layer_container.get_child(0).rect_size.y + item_sep
		var container_height = (Layer_container.get_child_count()-1) * item_height - item_sep
		var difference = Scroll_layer.rect_size.y - container_height
		if difference == clamp(difference, 0, item_height):
			parent.split_offset -= item_height
			pass
		
	emit_signal("layer_added")
	yield(get_tree(), "idle_frame")
	_on_Table_resized()
	resize_layer_icons()

func add_frame():
	var frame := base_frame.duplicate()
	connect_gui_element(frame, "_on_Frame_gui_input")
	Frame_container.add_child(frame)
	set_selected_frame()

func _on_AddFrame_pressed():
	add_frame()
	emit_signal("frame_added")
	_on_Table_resized()


func _on_Layer_gui_input(event, element):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			set_selected_layer(element.get_index())
		if !event.pressed and event.button_index == BUTTON_RIGHT:
			$LayerRightClick.popup()
			$LayerRightClick.rect_global_position = get_global_mouse_position() + Vector2.UP*$LayerRightClick.rect_size.y
			$LayerRightClick.set_item_disabled(0, Layer_container.get_child_count() <= 1)
			$LayerRightClick.connect("index_pressed", self, "on_LayerRightClick", [element], 4)

func _on_Frame_gui_input(event, element):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == BUTTON_LEFT:
			set_selected_frame(element.get_index())
		if !event.pressed and event.button_index == BUTTON_RIGHT:
			$FrameRightClick.popup()
			$FrameRightClick.rect_global_position = get_global_mouse_position() + Vector2.UP*$FrameRightClick.rect_size.y
			$FrameRightClick.set_item_disabled(0, Frame_container.get_child_count() <= 1)
			$FrameRightClick.connect("index_pressed", self, "on_FrameRightClick", [element], 4)

func delete_layer(id):
	var element = Layer_container.get_child(id)
	if !is_instance_valid(element): return
	element.free()
	if id == selected_layer:
		set_selected_layer(0)

func delete_frame(id):
	var element = Frame_container.get_child(id)
	if !is_instance_valid(element): return
	element.free()
	if id == selected_frame:
		set_selected_frame(0)

func on_LayerRightClick(index, element):
	if index == 0:
		var id = element.get_index()
		delete_layer(id)
		emit_signal("layer_removed", id)
		
#		var id = element.get_index()
##		var count = Layer_container.get_child_count()
#		element.free()
#		if id == selected_layer:
#			set_selected_layer(0)
##			set_selected_layer(wrapi(id + 1, 0, Layer_container.get_child_count()))
##			print(selected_layer)
#
##		element.queue_free()
#		emit_signal("layer_removed", id)

func on_FrameRightClick(index, element):
	if index == 0:
		var id = element.get_index()
		delete_frame(id)
		emit_signal("frame_removed", id)
		
#		var id = element.get_index()
#		element.free()
#		if id == selected_frame:
#			set_selected_frame(0)
##			self.selected_frame = wrapi(id + 1, 0, Frame_container.get_child_count())
#		emit_signal("frame_removed", id)
#	_on_Table_resized()


func _on_FrameRightClick_popup_hide():
	if $FrameRightClick.is_connected("index_pressed", self, "on_FrameRightClick"):
		$FrameRightClick.disconnect("index_pressed", self, "on_FrameRightClick")

func _on_LayerRightClick_popup_hide():
	if $LayerRightClick.is_connected("index_pressed", self, "on_LayerRightClick"):
		$LayerRightClick.disconnect("index_pressed", self, "on_LayerRightClick")


func _on_Table_resized():
	if !is_instance_valid(Frame_container): return
	Frame_container.rect_min_size.x = Frame_container.rect_size.y * Frame_container.get_child_count()


func _on_Visible_pressed():
	call_deferred("emit_signal", "visibility_pressed")
#	emit_signal("visibility_pressed")

func set_layer_image(image: Image, id := selected_layer):
	var tex = ImageTexture.new()
	tex.image = image
	tex.flags = 3
#	if !is_instance_valid(Layer_container.get_child(id)): return
	Layer_container.get_child(id).get_node("Icon").texture = tex

func set_frame_image(image: Image, id := selected_frame):
	var tex = ImageTexture.new()
	tex.image = image
	tex.flags = 3
#	print("frame ", id)
	if id < Frame_container.get_child_count():
		Frame_container.get_child(id).texture = tex
#	print(id)


func _on_HSplit_dragged(offset):
	resize_layer_icons()

func _physics_process(delta):
	if !Animator_play: return
	
	if Animator_play.pressed:
		var diff = Animator_framerate.value / 60.0
		anim_frame += diff
		var frame_count = Frame_container.get_child_count()
		if Animator_loop.pressed:
			anim_frame = wrapf(anim_frame, 0, frame_count)
		else:
			anim_frame = clamp(anim_frame, 0, frame_count - 1)
			if anim_frame == frame_count - 1:
				Animator_play.pressed = false
#		print(floor(anim_frame), ' ', anim_frame_prev)
#			pass
		if floor(anim_frame) != anim_frame_prev:
#			print('sel')
			emit_signal("anim_frame_changed", anim_frame_prev)
			anim_frame_prev = floor(anim_frame)
#			yield(get_tree(), "idle_frame")
		if floor(anim_frame) != selected_frame:
			set_selected_frame(floor(anim_frame))


func _on_Play_toggled(button_pressed):
	if button_pressed:
		anim_frame = 0
		anim_frame_prev = 0


func move_frame(source, destination):
	Frame_container.move_child(Frame_container.get_child(source), destination)
	emit_signal("frame_moved", source, destination)

func move_layer(source, destination):
	Layer_container.move_child(Layer_container.get_child(source), destination)
	emit_signal("layer_moved", source, destination)

func _on_Frame_frame_dragged(source, destination):
	move_frame(source, destination)
	set_selected_frame(destination-1)


func _on_Layer_layer_dragged(source, destination):
	move_layer(source, destination)
	set_selected_layer(destination-1)
