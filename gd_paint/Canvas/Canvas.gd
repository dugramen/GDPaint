tool
extends TextureRect

onready var host := get_parent()
onready var plugin: EditorPlugin = host.plugin

onready var Tool_container := host.get_node("HBoxContainer/PanelContainer/VBoxContainer/GridContainer")

onready var Grid_width := host.get_node("HBoxContainer/Settings/VBoxContainer/GridSize/Dimensions/Width")
onready var Grid_height := host.get_node("HBoxContainer/Settings/VBoxContainer/GridSize/Dimensions/Height")
onready var Grid_enabled := host.get_node("HBoxContainer/Settings/VBoxContainer/GridSize/Dimensions/CheckBox")

onready var Flip_horizontal := host.get_node("HBoxContainer/PanelContainer/VBoxContainer/Flip/HBox/Horixontal")
onready var Flip_vertical := host.get_node("HBoxContainer/PanelContainer/VBoxContainer/Flip/HBox/Vertical")

onready var Canvas_height := host.get_node("HBoxContainer/Settings/VBoxContainer/CanvasResize/Dimensions/Height")
onready var Canvas_width := host.get_node("HBoxContainer/Settings/VBoxContainer/CanvasResize/Dimensions/Width")
onready var Canvas_resize_mode := host.get_node("HBoxContainer/Settings/VBoxContainer/CanvasResize/Stretch/Mode")

onready var Color_left := host.get_node("HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/ColorPickerButtonLeft")
onready var Color_right := host.get_node("HBoxContainer/PanelContainer/VBoxContainer/HBoxContainer/ColorPickerButtonRight")

onready var Snap_mode := host.get_node("HBoxContainer/Settings/VBoxContainer/GridSize/Snap/OptionButton")
onready var Snap_check := host.get_node("HBoxContainer/Settings/VBoxContainer/GridSize/Snap/CheckBox")

onready var Modifier := host.get_node("HBoxContainer/PanelContainer/VBoxContainer/Modifier")

var undo_history := []
var redo_history := []

var image := Image.new()
var overlay := Image.new()
var layers := []

var pressed = false

var press_pos := Vector2()
var previous_pos := Vector2()
onready var previous_mouse_pos := get_global_mouse_position()
var brush_path := []

onready var left_color: Color = Color_left.color
onready var right_color: Color = Color_right.color
onready var current_color := left_color

onready var grid_size := Vector2(Grid_width.value, Grid_height.value) setget set_grid_size
func set_grid_size(val):
	grid_size = val
	Grid_width.value = grid_size.x
	Grid_height.value = grid_size.y

onready var canvas_size := Vector2(Canvas_width.value, Canvas_height.value) setget set_canvas_size
func set_canvas_size(val):
	canvas_size = val
	Canvas_width.value = val.x
	Canvas_height.value = val.y

var current_tool := "brush"
var override_tool := "brush"
var brush_size := 1

var selection := []
var selection_rect: Rect2
var stamp_pixels := {}

var sprite_path

onready var item_list: ItemList = host.get_node("HBoxContainer/PanelContainer/VBoxContainer/ItemList")
onready var undo_redo: UndoRedo = host.undo_redo


func load_sprite(path):
	sprite_path = path
	image.load(path)
	set_canvas_size(image.get_size())
	sync_image()
	update_history()


func save_sprite(path = sprite_path):
	if !path: 
		_on_SaveAs_pressed()
		return
	image.save_png(path)
	if plugin:
		plugin.get_editor_interface().get_resource_filesystem().scan()


func undo():
	if undo_history.size() > 1:
#		print('undo triggered')
		var current = undo_history.pop_back()
		var buffer = undo_history.back()
		redo_history.push_back(current)
		image.load_png_from_buffer(buffer)
		sync_image()
		sync_dimensions()

func redo():
	if !redo_history.empty():
#		print("redo triggered")
		var current = redo_history.pop_back()
		image.load_png_from_buffer(current)
		undo_history.push_back(image.save_png_to_buffer())
		sync_image()
		sync_dimensions()

func update_history(clear_redo := true):
	undo_history.append(image.save_png_to_buffer())
	if clear_redo:
		redo_history.clear()
	
#	if !is_instance_valid(undo_redo): return
#	undo_redo.create_action("Painted")
#	undo_redo.add_do_property(self, "undo_history", val)
#	undo_redo.add_undo_method(self, "undo")
#	undo_redo.commit_action()


func sync_dimensions():
	Canvas_height.value = image.get_height()
	Canvas_width.value = image.get_width()


func sync_image():
	texture.image = image
	overlay = image.duplicate()
#	overlay.fill(Color(0,0,0,0))
#	$Overlay.texture.image = overlay

#func get_extents():
#	return host.get_global_rect()

func _ready():
	image = Image.new()
	image.create(canvas_size.x, canvas_size.y, false, 5)
	image.fill(Color(0,0,0,0))
	sync_image()
	update_history()
	
	for p in [Vector2(1,1), Vector2(8,1), Vector2(1, 8), Vector2(8,7)]:
		print(p, ": ", get_closest_vect(p, [
			Vector2(), Vector2(10,0), Vector2(0,10), Vector2(10,10)
		]))

func _physics_process(delta):
	if !selection.empty():
		update()


func _input(event):
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	

func fake_input(event):
	if !host: return
	
#	if Input.get_mouse_button_mask() in [BUTTON_MASK_LEFT, BUTTON_MASK_RIGHT]:
#		if !get_extents().has_point(get_global_mouse_position()): 
#			mouse_filter = Control.MOUSE_FILTER_IGNORE
#			return
#		else:
#			mouse_filter = Control.MOUSE_FILTER_STOP
	
	if !selection.empty():
		handle_cut()
	else:
		update()
	handle_override_tool(event)
	
	if Input.is_key_pressed(KEY_SPACE):
		rect_position += get_global_mouse_position() - previous_mouse_pos
	previous_mouse_pos = get_global_mouse_position()
#	update()
	
	if event is InputEventMouse:
		if event.is_pressed():
			var scroll = int(event.button_index == BUTTON_WHEEL_UP) - int(event.button_index == BUTTON_WHEEL_DOWN)
			if scroll != 0:
				var global_mouse := get_global_mouse_position()
				var loc_mouse: Vector2 = global_mouse - rect_global_position
				var pixel := loc_mouse / rect_scale.x
				
				rect_scale += scroll * Vector2.ONE * .1 * rect_scale.x
				rect_global_position = -(pixel*rect_scale.x - global_mouse)

		
		# Panning
#		var mid: Vector2 = get_parent().rect_position + get_parent().rect_size/2.0
#		var half = rect_size/2.0
#		mid -= half
#		half *= rect_scale.x
#		rect_position.x = clamp(rect_position.x, (mid.x - half.x), mid.x + half.x)
#		rect_position.y = clamp(rect_position.y, (mid.y - half.y), mid.y + half.y)

func gui_input(raw_event):
	mouse_filter = Control.MOUSE_FILTER_PASS
	fake_input(raw_event)
	
	if raw_event is InputEventMouse:
		var event = raw_event.duplicate()
#		event.position -= rect_position
#		event.position /= rect_scale.x
		var pos = (event.position - rect_position) / rect_scale.x
		pos.x *= image.get_width() / rect_size.x
		pos.y *= image.get_height() / rect_size.y
		event.position = pos.floor()
		
		if event is InputEventMouseButton and event.button_index in [BUTTON_LEFT, BUTTON_RIGHT]:
			pressed = event.pressed
			if event.pressed:
				press_pos = event.position
				previous_pos = event.position
				brush_path.clear()
		
		var limit := get_image_rect()
		if !selection.empty():
			limit = selection_rect
		
		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
#			if check_alt: right_color = hover_color
			current_color = right_color
		elif Input.is_mouse_button_pressed(BUTTON_LEFT):
#			if check_alt: left_color = hover_color
			current_color = left_color
		
		handle_drag(event, "paint_" + override_tool, current_color, limit)
		
		previous_pos = event.position

func _draw():
	if !host: return
	
	if !selection.empty():
		var bar_width := 2.0
		var col = Color.white
		var offset: float =  wrapf(OS.get_ticks_msec() / 1000.0, 0.0, 1.0) * bar_width * 2.0
		for val in [0, 1]:
			var ob = "selection_rect"
			selection_rect
			var parallel = [Vector2.RIGHT, Vector2.DOWN][val]
			var perpendicular = [Vector2.DOWN, Vector2.RIGHT][val]
			var pos1 = [selection_rect.position.x, selection_rect.position.y][val]
			var end1 = [selection_rect.end.x, selection_rect.end.y][val]
			var pos2 = [selection_rect.position.y, selection_rect.position.x][val]
			var end2 = [selection_rect.end.y, selection_rect.end.x][val]
			for i in range(pos1 - bar_width*2, end1, bar_width):
				col = Color.black if col == Color.white else Color.white
				var pos: float = i + offset
				var x1 = clamp(pos, pos1, end1)
				var x2 = clamp(pos + bar_width, pos1, end1)
				draw_line(parallel*x1 + perpendicular*pos2, parallel*x2 + perpendicular*pos2, col, 1)
				draw_line(parallel*x1 + perpendicular*end2, parallel*x2 + perpendicular*end2, col, 1)
	
	draw_rect(Rect2(get_local_mouse_position().floor(), Vector2.ONE), Color.white, false)
	
	var rect = get_image_rect()
	var minimum_grid_visible := 4.0
	var grid_color := Color(1,1,1,.25)
	
	var xgrid = [rect.position.x, rect.end.x]
	var ygrid = [rect.position.y, rect.end.y]
	
	if Grid_enabled.pressed:
		if grid_size.x * rect_scale.x >= minimum_grid_visible:
			xgrid += range(rect.position.x, 1+rect.end.x, self.grid_size.x)
		if grid_size.y * rect_scale.y >= minimum_grid_visible:
			ygrid += range(rect.position.y, 1+rect.end.y, self.grid_size.y)
	
	for i in xgrid:
		draw_line(Vector2(i, rect.position.y), Vector2(i, rect.end.y), grid_color, 1.0)
	for i in ygrid:
		draw_line(Vector2(rect.position.x, i), Vector2(rect.end.x, i), grid_color, 1.0)
	
#	if current_tool == "stamp" and !stamp_pixels.empty():
#		draw_texture($Overlay.texture, )



func handle_drag(event: InputEventMouse, method := "paint_line", color: Color = left_color, limit := get_image_rect()):
	if !has_method(method): return
	
	var start_pos = press_pos.floor()
	var end_pos = event.position.floor()
	var base_color: Color = color
	
	if Snap_check.pressed:
		var sp_snapped = Vector2(floor(start_pos.x/grid_size.x)*grid_size.x, floor(start_pos.y/grid_size.y)*grid_size.y)
		var ep_snapped = Vector2(floor(end_pos.x/grid_size.x)*grid_size.x, floor(end_pos.y/grid_size.y)*grid_size.y)
		match Snap_mode.selected:
			1:
				start_pos = sp_snapped
				end_pos = ep_snapped
		
			2:
				start_pos = get_closest_vect(start_pos,[
					sp_snapped, sp_snapped + Vector2.RIGHT*(grid_size.x - 1),
					sp_snapped + Vector2.DOWN*(grid_size.y - 1), sp_snapped + grid_size - Vector2.ONE*1
				])
				end_pos = get_closest_vect(end_pos,[
					ep_snapped, ep_snapped + Vector2.RIGHT*(grid_size.x - 1),
					ep_snapped + Vector2.DOWN*(grid_size.y - 1), ep_snapped + grid_size - Vector2.ONE*1
				])
			
			0:
				start_pos = Vector2(stepify(start_pos.x, grid_size.x), stepify(start_pos.y, grid_size.y))
				end_pos = Vector2(stepify(end_pos.x, grid_size.x), stepify(end_pos.y, grid_size.y))
				if end_pos.x > start_pos.x:
					end_pos.x -= 1
				if start_pos.x > end_pos.x:
					start_pos.x -= 1
				if start_pos.y > end_pos.y:
					start_pos.y -= 1
				if end_pos.y > start_pos.y:
					end_pos.y -= 1
	
	var release_check = (event is InputEventMouseButton 
		and !event.pressed 
		and event.button_index in [BUTTON_LEFT, BUTTON_RIGHT])
	
	var target_image
	if release_check:
		target_image = image
	if pressed: 
#		if method == "paint_fill":
#			return
		overlay = image.duplicate()
		target_image = overlay
	
	var hflip = Flip_horizontal.pressed
	var vflip = Flip_vertical.pressed
	var center = vect_to_pair(limit.position + limit.size/2.0)
	
	var any_change = false
	if target_image != null:
		var pixels = call(method, start_pos, end_pos)
		var is_dict = pixels is Dictionary
		target_image.lock()
		for pixel in pixels:
			var flips = [pixel]
			if hflip:
				for p in flips + []:
					var relative = pixel - center
					flips.append(Vector2(center.x - relative.x-.5, p.y))
			if vflip:
				for p in flips + []:
					var relative = pixel - center
					flips.append(Vector2(p.x, center.y - relative.y-.5))
			
			for p in flips:
#				p = vect_to_pair(p)
				if limit.has_point(p):
					var col = base_color
					if is_dict:
						col = pixels[pixel]
#						col = pixels[pixel].blend(base_color)
#						print(base_color)
					target_image.set_pixelv(p, col)
					any_change = true
		target_image.unlock()
		texture.image = target_image
		
		if release_check and any_change:
			update_history()
	
	return


func handle_cut():
	if (true
#		and current_tool == "selection"
		and !selection.empty() 
		and Input.is_key_pressed(KEY_CONTROL) 
		and Input.is_key_pressed(KEY_X)
	):
		stamp_pixels.clear()
		var origin = get_local_mouse_position()
		image.lock()
		for pixel in selection:
			var pos = pixel
			stamp_pixels[pos] = image.get_pixelv(pixel)
			image.set_pixelv(pixel, Color(0,0,0,0))
		image.unlock()
		texture.image = image
		current_tool = "stamp"
		highlight_current_tool()
		selection.clear()
		update_history()


func handle_override_tool(event):
	var key_map := {
		KEY_B: "brush",
		KEY_C: "circle",
		KEY_R: "rect",
		KEY_E: "ellipse",
		KEY_M: "selection",
		KEY_F: "fill",
		KEY_L: "line",
	}
	
#	override_tool = current_tool
	
	if event is InputEventKey:
		for key in key_map:
			if (event.pressed
			and !event.echo
			and event.scancode == key):
				var label = key_map[key]
				current_tool = label
				if event.shift and has_method("paint_"+label + "_fill"):
					current_tool = label + "_fill"
		
		# Hotkeys
		if (event.pressed and !event.echo):
			# Control
			if (true
				and !event.shift
				and !event.alt
				and event.control
			):
				if event.scancode == KEY_A:
					current_tool = "selection"
					selection.clear()
					selection_rect = get_image_rect()
					for x in range(image.get_width()):
						for y in range(image.get_height()):
							selection.append(vect_to_pair(Vector2(x,y)))
			# Shift
			if (true
				and !event.control
				and !event.alt
				and event.shift
			):
				match event.scancode:
					KEY_S:
						Snap_check.pressed = !Snap_check.pressed
					KEY_G:
						Grid_enabled.pressed = !Grid_enabled.pressed
						update()
					
					KEY_H:
						Flip_horizontal.pressed = !Flip_horizontal.pressed
					KEY_V:
						Flip_vertical.pressed = !Flip_vertical.pressed
				
		
	override_tool = current_tool
		
	if Input.is_key_pressed(KEY_SHIFT):
		if Input.is_key_pressed(KEY_CONTROL):
			override_tool = "rect_fill"
		else:
			override_tool = "line"
	elif Input.is_key_pressed(KEY_CONTROL):
		override_tool = "rect"
	elif Input.is_key_pressed(KEY_ALT):
		override_tool = "color_pick"

	if !has_method("paint_" + override_tool):
		override_tool = current_tool
		
	highlight_current_tool(override_tool)


func highlight_current_tool(val = current_tool):
#	print(val)
	Tool_container.highlight_tool(val)
	return
	if !is_instance_valid(item_list): return
	for i in range(item_list.get_item_count()):
		var text = item_list.get_item_text(i)
		if text.to_lower() == val:
			item_list.select(i)
			break

func highlight_current_colors():
	Color_left.color = left_color
	Color_right.color = right_color



func paint_stamp(start_pos: Vector2, end_pos: Vector2):
	var pixels := {}
	for pixel in stamp_pixels:
		var color: Color = stamp_pixels[pixel]
		
		if color == Color(0,0,0,0): continue
		
		var pos = pixel + end_pos
		pixels[vect_to_pair(pos)] = color
	return pixels



func paint_brush(a, pos: Vector2):
	var pixels = paint_line(previous_pos, pos)
	brush_path.append_array(pixels)
	return brush_path


func paint_line(start_pos: Vector2, end_pos: Vector2) -> Array:
	var pixels := []
	var rect = points_to_rect(start_pos, end_pos)
	
	if start_pos == end_pos: 
		if not start_pos in pixels:
			pixels.append(start_pos)
	else:
		var diff := end_pos - start_pos
		var maxim: float = max(max(rect.size.x, rect.size.y), 1)
#		if maxim == 0:
#			return [start_pos]
		
		var aspect = diff
		aspect.x /= maxim
		aspect.y /= maxim
		for i in range(maxim + 1):
			var pos = aspect * i
			pos += start_pos
			if not pos.round() in pixels:
				pixels.append(vect_to_pair(pos))
	
	return pixels


func aspect_end_pos(start_pos, end_pos) -> Vector2:
	var diff = (end_pos - start_pos)
	var r = max(diff.abs().x, diff.abs().y)
	end_pos = start_pos + diff.sign()*r
	return end_pos


func paint_square(start_pos: Vector2, end_pos: Vector2):
	return paint_rect(start_pos, aspect_end_pos(start_pos, end_pos))
	

func paint_square_fill(start_pos: Vector2, end_pos: Vector2):
	return paint_rect_fill(start_pos, aspect_end_pos(start_pos, end_pos))


func paint_rect(start_pos: Vector2, end_pos: Vector2) -> Array:
	var pixels := []
	var rect = points_to_rect(start_pos, end_pos)
#	for i in range(min(start_pos.x, end_pos.x), 1+max(start_pos.x, end_pos.x)):
	for i in range(rect.position.x, rect.position.x + rect.size.x + 1):
		pixels.append(vect_to_pair(Vector2(i, start_pos.y)))
		pixels.append(vect_to_pair(Vector2(i, end_pos.y)))
#	for i in range(min(start_pos.y, end_pos.y), 1+max(start_pos.y, end_pos.y)):
	for i in range(rect.position.y, rect.position.y + rect.size.y + 1):
		pixels.append(vect_to_pair(Vector2(start_pos.x, i)))
		pixels.append( vect_to_pair(Vector2(end_pos.x, i)) )
	return pixels


func paint_rect_fill(start_pos: Vector2, end_pos: Vector2) -> Array:
	var pixels := []
	var rect = points_to_rect(start_pos, end_pos)
#	pixels += fill(rect.position + rect.size/2.0, paint_rect(start_pos, end_pos), rect)
	
	for i in range(rect.position.x, rect.position.x + rect.size.x + 1):
		for j in range(rect.position.y, rect.position.y + rect.size.y + 1):
			pixels.append( vect_to_pair(Vector2(i,j)) )
	return pixels


func paint_circle(start_pos: Vector2, end_pos: Vector2) -> Array:
	return paint_ellipse(start_pos, aspect_end_pos(start_pos, end_pos))


func paint_circle_fill(start_pos: Vector2, end_pos: Vector2) -> Array:
	return paint_ellipse_fill(start_pos, aspect_end_pos(start_pos, end_pos))
	
	var pixels := []
	var rect := points_to_rect(start_pos, end_pos)
	var radius = rect.size.length()
	var circle_rect = Rect2(start_pos, Vector2()).grow(radius)
	
	for x in range(circle_rect.position.x, 1+circle_rect.position.x + circle_rect.size.x):
		for y in range(circle_rect.position.y, 1+circle_rect.position.y + circle_rect.size.y):
			var pos = Vector2(x,y)
			if (pos - start_pos).abs().length() < radius:
				pixels.append(vect_to_pair(pos))
	
	return pixels


func paint_ellipse(start_pos: Vector2, end_pos: Vector2) -> Array:
	if start_pos.is_equal_approx(end_pos): return [end_pos]
	
	var pixels := []
	var rect: Rect2 = points_to_rect(start_pos, end_pos)
	var center = rect.position + rect.size/2.0
	var radius = (rect.size) / 2.0
	var increment := 1
	var pos = center + Vector2.RIGHT*radius.x
	for i in range(0, 360 + increment, increment):
		var dir := Vector2.RIGHT.rotated(deg2rad(i))
		dir.x *= radius.x
		dir.y *= radius.y
		pixels.append_array(paint_line(pos, center+dir))
		pos = center + dir
	
	return pixels


func paint_ellipse_fill(start_pos: Vector2, end_pos: Vector2) -> Array:
	var rect := points_to_rect(start_pos, end_pos)
	var outline := paint_ellipse(start_pos, end_pos)
	
	var pixels = outline + fill(rect.position + rect.size / 2.0, outline, rect)
	return pixels


func paint_selection(start_pos: Vector2, end_pos: Vector2):
	var rect := points_to_rect(start_pos, end_pos).grow_individual(0,0,1,1)
	selection.clear()
	var limits := get_image_rect()
	selection_rect = rect.clip(limits)
	
	if !rect.has_no_area(): 
		for x in range(rect.position.x, rect.end.x + 1):
			for y in range(rect.position.y, rect.end.y + 1):
#				image.lock()
				var pos := vect_to_pair(Vector2(x,y))
				if !limits.has_point(pos): continue
				selection.append(pos)
#				selection[pos] = image.get_pixel(x, y)
#				image.unlock()
	
	return []


func paint_color_pick(spos: Vector2, epos: Vector2):
	var col := Color(0,0,0,0)
	if get_image_rect().has_point(epos): 
		image.lock()
		col = image.get_pixelv(epos)
		image.unlock()
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		left_color = col
		highlight_current_colors()
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		right_color = col
		highlight_current_colors()
	
	return []


func paint_fill(start_pos, end_pos):
	var limits := get_image_rect()
	if !limits.has_point(end_pos): return []
	var drag_rect = points_to_rect(start_pos, end_pos)
	
	var result := []
	var border := []
	image.lock()
	var color = image.get_pixelv(end_pos)
	for x in range(limits.position.x, limits.end.x):
		for y in range(limits.position.y, limits.end.y):
			var pos = vect_to_pair(Vector2(x,y))
			var col = image.get_pixel(x,y)
			if !col.is_equal_approx(color):
				border.append(pos)
	image.unlock()
#	print(border)
	result = fill(end_pos, border, limits)
	return result


func fill(point: Vector2, border = [], limits := Rect2(Vector2(), image.get_size())):
	point = vect_to_pair(point)
	if point in border: return border
	var result = [point]
#	result.append(point)
	var i = result.size()-1
	var map := {}
	for x in range(limits.position.x, 1+limits.end.x):
		for y in range(limits.position.y, 1+limits.end.y):
			var pos = vect_to_pair(Vector2(x,y))
			map[pos] = false
	for p in result:
		map[p] = true
	for p in border:
		map[p] = true
	while i < result.size():
		for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			var check := vect_to_pair(result[i] + dir)
			if !limits.has_point(check): continue
#			if check in result: continue
			
			if map[check]: continue
			map[check] = true
			
			result.append(check)
		i += 1
	
	return result



func points_to_rect(point1: Vector2, point2: Vector2, rounded := true) -> Rect2:
	var rect: Rect2
	var x = min(point1.x, point2.x)
	var y = min(point1.y, point2.y)
	var w = max(point1.x, point2.x) - x
	var h = max(point1.y, point2.y) - y
	rect = Rect2(vect_to_pair(Vector2(x, y)), vect_to_pair(Vector2(w,h)))
	if !rounded:
		rect = Rect2(x,y,w,h)
	return rect

func vect_to_pair(point: Vector2) -> Vector2:
	return Vector2(
		int(round(point.x)), int(round(point.y))
	)


func get_closest_vect(point: Vector2, list: Array) -> Vector2:
	var min_dist = grid_size.length_squared() + 100
	var index = 0
	for i in range(list.size()):
#		var pt_next = list[i]
		var dist = point.distance_squared_to(list[i])
		if dist <= min_dist:
			index = i
			min_dist = dist
	
	return list[index]


func get_image_rect() -> Rect2:
	return Rect2(Vector2(), image.get_size())


func add_modifier():
	for child in Modifier:
		child.queue_free()
	
	


func _on_ColorPickerButton_color_changed(col):
	left_color = col

func _on_ColorPickerButtonRight_color_changed(col):
	right_color = col


func _on_GridContainer_tool_selected(node: Node):
	if node is Button:
		current_tool = node.text.to_lower()


func _on_SpinBox_value_changed(value):
	brush_size = value


func _on_Width_value_changed(value):
	set_dimensions(value, image.get_height())

func _on_Height_value_changed(value):
	set_dimensions(image.get_width(), value)

func set_dimensions(width, height):
	var pos = rect_position
	var scale = rect_scale
	
	match Canvas_resize_mode.selected:
		0:
			image.crop(width, height)
		1:
			image.resize(width, height, Image.INTERPOLATE_NEAREST)
		2:
			image.resize(width, height, Image.INTERPOLATE_BILINEAR)
		3:
			image.resize(width, height, Image.INTERPOLATE_CUBIC)
		4:
			image.resize(width, height, Image.INTERPOLATE_TRILINEAR)
		5:
			image.resize(width, height, Image.INTERPOLATE_LANCZOS)
			
	sync_image()
	update_history()
	
	yield(get_tree(), "idle_frame")
	rect_position = pos
	rect_scale = scale


func _on_Button_pressed():
	save_sprite()


func _on_SaveAs_pressed():
	$FileDialog.mode = 4
	$FileDialog.set_as_minsize()
	$FileDialog.popup_centered_ratio()


func _on_Load_pressed():
	$FileDialog.mode = 0
	$FileDialog.set_as_minsize()
	$FileDialog.popup_centered_ratio()


func _on_FileDialog_file_selected(path):
	if $FileDialog.mode == 0:
		sprite_path = path
		load_sprite(path)
	elif $FileDialog.mode == 4:
		save_sprite(path)


func _on_ItemList_tool_selected(text):
	current_tool = text.to_lower()


func _on_Undo_pressed():
	undo()


func _on_Redo_pressed():
	redo()


func _on_grid_Width_value_changed(value):
	grid_size.x = value
	update()


func _on_grid_Height_value_changed(value):
	grid_size.y = value
	update()


func _on_CheckBox_toggled(button_pressed):
	update()
