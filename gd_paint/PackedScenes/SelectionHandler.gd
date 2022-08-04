tool
extends Control

var default_image_path = "res://icon.png"
var image = Image.new()
var anchoring_mode

var image_sign := Vector2.ONE
var temp_sign := Vector2.ONE


var margins :=  {
	"left": [Vector2.RIGHT, "right"],
	"top": [Vector2.DOWN, "bottom"],
	"right": [Vector2.RIGHT, "left"],
	"bottom": [Vector2.DOWN, "top"],
}

func _ready():
	var file = File.new()
	file.open(default_image_path, File.READ)
	var buffer = file.get_buffer(file.get_len())
	image.load_png_from_buffer(buffer)
	file.close()
	image.lock()
	$Center/TextureRect.texture.image = image
	
	resize_image()
	
	for child in get_children():
		if child is ColorRect:
			for margin in margins:
				child.set_meta(margin, margin in child.name.to_lower())
			child.connect("gui_input", self, "on_handler_gui_input", [child])


func reset_metas():
	for child in get_children():
		if child is ColorRect:
			for margin in margins:
				child.set_meta(margin, margin in child.name.to_lower())

#func _input(event):
#	pass

func set_pos(pos: Vector2):
#	rect_position = pos - $Center.rect_position
	rect_position = pos

func get_pos() -> Vector2:
	return (rect_position + $Center.rect_position).round()

func set_selection_size(s_size: Vector2):
#	rect_size = s_size + $TopLeft.rect_size + $BottomRight.rect_size
	rect_size = s_size

func set_image(img: Image):
	image_sign = Vector2.ONE
	temp_sign = image_sign
	image = img.duplicate()
	$Center/TextureRect.rect_size = image.get_size()
	$Center/TextureRect.texture.image = image
	_on_CanvasOverrider_resized()
	update()
#	_on_Center_resized()


func get_image() -> Image:
	return $Center/TextureRect.texture.image

func get_image_rect():
	return Rect2(Vector2(), get_image().get_size())


func _draw():
	var rect = Rect2($Center.rect_position, $Center.rect_size)
	draw_rect(rect, Color.black, false)


func on_handler_gui_input(event: InputEvent, node: Control):
	if event is InputEventMouseButton:
		if event.pressed:
			temp_sign = image_sign
			reset_metas()
	if event is InputEventMouseMotion:
		if event.button_mask == BUTTON_MASK_LEFT:
			for margin in margins:
				
				if node.get_meta(margin):
#					var pos = node.rect_position
					var pos = Vector2(lerp(0, rect_size.x, node.anchor_left), lerp(0, rect_size.y, node.anchor_top))
					var relative = ((event.position + pos) + rect_position).floor().dot(margins[margin][0])
					set_margin_clamped(margin, relative, node)


func set_draggable(val):
	$Center.mouse_filter = MOUSE_FILTER_STOP if val else MOUSE_FILTER_IGNORE

func update_image(img: Image):
#	tranform_image(image)
#	image_sign = Vector2.ONE
	image = img.duplicate()
	$Center/TextureRect.texture.image = img.duplicate()
#	image = $Center/TextureRect.texture.image.duplicate()


func vector_apply_negativity(vec1, vec2) -> Vector2:
	if vec2.x == -1:
		vec1.x *= -1
	if vec2.y == -1:
		vec1.y *= -1
	print("applied ", vec1)
	return vec1


func set_margin_clamped(margin, position, node: ColorRect):
	var complement = margins[margin][1]
	
	var margin_pos = get("margin_" + margin)
	var new_pos = position
	var complement_pos = get("margin_" + complement)
	
	if new_pos == complement_pos:
		return
	
	if complement_pos == clamp(complement_pos, min(margin_pos, new_pos), max(margin_pos, new_pos)):
		image_sign = vector_apply_negativity(temp_sign, -1 * margins[margin][0])
		temp_sign = image_sign
		set("margin_" + complement, new_pos)
		set("margin_" + margin, complement_pos)
		
		node.set_meta(margin, !node.get_meta(margin))
		node.set_meta(complement, !node.get_meta(complement))
#		set("margin_" + margin, complement_pos)
#		resize_image()
		print(image_sign)
		pass
		
	else:
		set("margin_" + margin, new_pos)
	

func flip_x():
	image.flip_x()
func flip_y():
	image.flip_y()


func resize_image():
	var img: Image = image.duplicate()
	var control_rect = Rect2(Vector2(), rect_size)
	var control_size = control_rect.size
	
	transform_image(img)
	
	$Center/TextureRect.texture.image = img
	$Center.rect_size = control_rect.size
	$Center.rect_position = control_rect.position
#	$Center/TextureRect.rect_size = control_size

func get_image_transformed(imag: Image = image):
	var img = imag.duplicate()
	img.resize(rect_size.x , rect_size.y, Image.INTERPOLATE_NEAREST)
	if image_sign.x == -1:
		img.flip_x()
	if image_sign.y == -1:
		img.flip_y()
	return img

func transform_image(img: Image = image):
#	var img = image
	img.resize(rect_size.x , rect_size.y, Image.INTERPOLATE_NEAREST)
	if image_sign.x == -1:
		img.flip_x()
	if image_sign.y == -1:
		img.flip_y()
	image_sign = Vector2.ONE
	temp_sign = Vector2.ONE

func _on_Center_resized():
	return


func _on_SelectionHandler_resized():
	resize_image()



func _on_Center_gui_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == BUTTON_MASK_LEFT:
			rect_position += (event.relative)


func _on_CanvasOverrider_resized():
	return
	for child in get_children():
		child.rect_min_size = (Vector2.ONE*8)/get_parent_control().rect_scale
	
#	emit_signal("sort_children")
