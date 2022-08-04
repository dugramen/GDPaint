tool
extends TextureRect

const PaintDataPath := "res://addons/gd_paint/PaintData/paint_data.ini"
var PaintData := ConfigFile.new()

onready var host := get_parent()
onready var plugin = host.plugin

onready var Canvas_overrider := host.get_node("CanvasOverrider")
onready var Selection_handler := Canvas_overrider.get_node("SelectionHandler")

onready var Right_panel := host.get_node("MarginContainer/HBoxContainer/HSplit/Settings/VBoxContainer")
onready var Left_panel := host.get_node("MarginContainer/HBoxContainer/PanelContainer/VBoxContainer")

onready var Tool_container := Left_panel.get_node("Tools/ToolContainer/GridContainer")
onready var Modifier_container := Left_panel.get_node("Modifier/ModifierContainer")

onready var Flip_container := Modifier_container.get_node("Flip")
onready var Flip_horizontal := Flip_container.get_node("HBox/Horixontal")
onready var Flip_vertical := Flip_container.get_node("HBox/Vertical")

onready var Brush_container := Left_panel.get_node("Brushes/BrushContainer")
onready var Brush_list := Brush_container.get_node("BrushList")
onready var Brush_size := Brush_container.get_node("BrushMod/BrushSize")
onready var Brush_angle := Brush_container.get_node("BrushMod/BrushAngle")

onready var Grid_container := Right_panel.get_node("Grid/GridSize")
onready var Grid_width := Grid_container.get_node("Dimensions/Width")
onready var Grid_height := Grid_container.get_node("Dimensions/Height")
onready var Grid_enabled := Grid_container.get_node("Dimensions/CheckBox")

onready var Snap_mode := Grid_container.get_node("Snap/OptionButton")
onready var Snap_check := Grid_container.get_node("Snap/CheckBox")

onready var Canvas_resize_container := Right_panel.get_node("Canvas/CanvasResize")
onready var Canvas_height := Canvas_resize_container.get_node("Dimensions/Height")
onready var Canvas_width := Canvas_resize_container.get_node("Dimensions/Width")
onready var Canvas_resize_mode := Canvas_resize_container.get_node("Stretch/Mode")

onready var Canvas_area := host.get_node("MarginContainer/HBoxContainer/HSplit/LayerFrameContainer/VSplitContainer/Control")

onready var Color_container := Left_panel.get_node("Colors/ColorContainer")
onready var Color_left := Color_container.get_node("HBoxContainer/ColorPickerButtonLeft")
onready var Color_right := Color_container.get_node("HBoxContainer/ColorPickerButtonRight")

onready var Tiled_mode_h := Right_panel.get_node("Tiled/Tiling/TiledMode/TileH")
onready var Tiled_mode_v := Right_panel.get_node("Tiled/Tiling/TiledMode/TileV")
onready var Tiled_wrapped := Right_panel.get_node("Tiled/Tiling/TileWrap")

onready var Alpha_mode_container := Modifier_container.get_node("AlphaMode")
onready var Pixel_perfect := Modifier_container.get_node("PixelPerfect")

onready var Selection_controls := Modifier_container.get_node("SelectionControls")
onready var Selection_copy := Selection_controls.get_node("Copy")
onready var Selection_cut := Selection_controls.get_node("Cut")
onready var Selection_paste := Selection_controls.get_node("Paste")

onready var Table_container := host.get_node("MarginContainer/HBoxContainer/HSplit/LayerFrameContainer/VSplitContainer/Table")

onready var default_modifiers := [Flip_container, Alpha_mode_container]

var undo_history := []
var redo_history := []

var image := Image.new()
var overlay := Image.new()
var pencil_image: Image 
var frames := [[image]]

var pressed = false
var released = false

var press_pos := Vector2()
var previous_pos := Vector2()
onready var previous_mouse_pos := get_global_mouse_position()
var brush_path := []

var frame_just_selected := -1

onready var left_color: Color = Color_left.color
onready var right_color: Color = Color_right.color
onready var current_color := left_color
var current_brush: TextureRect

onready var grid_size := Vector2(Grid_width.value, Grid_height.value) setget set_grid_size
func set_grid_size(val):
	grid_size = val
	$GridDrawer.update()
	Grid_width.value = grid_size.x
	Grid_height.value = grid_size.y

onready var canvas_size := Vector2(Canvas_width.value, Canvas_height.value) setget set_canvas_size
func set_canvas_size(val):
	canvas_size = val
	rect_size = val
	Canvas_width.value = val.x
	Canvas_height.value = val.y

var current_tool := "brush"
var override_tool := "brush"
var brush_size := 1

var selection := []
var selection_rect: Rect2
var stamp_pixels := {}

var sprite_path

var ready = false

#onready var item_list: ItemList = host.get_node("HBoxContainer/PanelContainer/VBoxContainer/ItemList")
onready var undo_redo: UndoRedo = host.undo_redo

var stamp_scene := preload("res://addons/gd_paint/PackedScenes/Stamp.tscn")


func _ready():
	PaintData.load(PaintDataPath)
	Selection_handler.visible = false
	
	image = Image.new()
	image.create(canvas_size.x, canvas_size.y, false, 5)
	image.fill(Color(0,0,0,0))
	frames[0][0] = image
	
	yield(get_tree(), "idle_frame")
	sync_image()
	
	choose_modifiers(default_modifiers + [Pixel_perfect])
	
	var first = add_stamp(paint_ellipse_fill(Vector2(), Vector2.ONE * 15), Vector2.ONE*15)
	first.set_meta("function", "paint_ellipse_fill")
	add_stamp(paint_rect_fill(Vector2(), Vector2.ONE), Vector2.ONE).set_meta("function", "paint_rect_fill")
	add_stamp(paint_line(Vector2(0, 3), Vector2(6, 3)), Vector2.ONE * 6).set_meta("function", "paint_line")
	on_stamp_pressed(first)
	
	update_history()
	call_deferred("recenter_image")
	
	ready = true


func load_sprite(path):
	rect_scale = Vector2.ONE
	sprite_path = path
	
#	pack_frames()
	
	image.load(path)
	texture.image = image
	set_canvas_size(image.get_size())
	
#	frames = [[image.save_png_to_buffer()]]
	
	unpack_frames(PaintData.get_value(path, "frames", [[image.save_png_to_buffer()]] ))
	
	sync_image()
	recenter_image()
	update_history()
#	_on_ZoomReset_pressed()


func save_sprite(path = sprite_path):
	if !path: 
		_on_SaveAs_pressed()
		return
	
	texture.image.save_png(path)
	PaintData.set_value(path, "frames", pack_frames())
	PaintData.save(PaintDataPath)
	
	if plugin:
		plugin.get_editor_interface().get_resource_filesystem().scan()


func save_animated_texture(path = sprite_path):
	if !path: 
		_on_SaveAs_pressed()
		return
	
	var _texture := AnimatedTexture.new()
	_texture.frames = frames.size()
	_texture.fps = Table_container.get_fps()
	
	for i in frames.size():
		var frame = frames[i]
		var tex := render_frame(frame)
		_texture.set_frame_texture(i, tex)
	
	ResourceSaver.save(path + ".tres", _texture)
	print("saved")
	
	if plugin:
		plugin.get_editor_interface().get_resource_filesystem().scan()


func render_frame(layers: Array) -> ImageTexture:
	layers = layers.duplicate()
	var tex := ImageTexture.new()
	var img: Image = layers.pop_front().duplicate()
	for layer in layers:
		img.blend_rect(layer, get_image_rect(), Vector2())
	tex.create_from_image(img, 3)
	return tex


func pack_frames():
	var data = []
	for frm in frames:
		var buff := []
		for lyr in frm:
			buff.append(lyr.save_png_to_buffer())
		data.append(buff)
	return data

func unpack_frames(data: Array):
	# loop to max of frame and data instead
	# if greater than data, clear the frame, as it means it was just created
	# figure out how to detect layer deletion
	frames.clear()
	var frame_count = Table_container.Frame_container.get_child_count()
	var layer_count = Table_container.Layer_container.get_child_count()
	for i in max(data.size(), frame_count):
		var layer := []
		if i >= data.size():
#			delete_frame(i)
			Table_container.delete_frame(i)
			print("did the frame delete")
			
			continue
		if i >= frame_count:
			Table_container.add_frame()
			print("did the frame add")
		
		var frm = data[i]
		for j in max(frm.size(), layer_count):
			if j >= frm.size():
#				delete_layer(j)
				Table_container.delete_layer(j)
				print("did the layer delete")
				continue
			if j >= layer_count:
				Table_container.add_layer()
				print("did the layer add")
			
			var lyr = frm[j]
			var img = Image.new()
			img.load_png_from_buffer(lyr)
			layer.append(img)
#			frames[i][j].load_png_from_buffer(lyr)
		frames.append(layer)


func undo():
#	print(undo_history)
	if undo_history.size() > 1:
#		print('undo triggered')
		var current = undo_history.pop_back()
		var buffer = undo_history.back()
		redo_history.push_back(current)
#		image.load_png_from_buffer(buffer)
		unpack_frames(buffer)
		sync_image()
		sync_dimensions()


func redo():
	if !redo_history.empty():
#		print("redo triggered")
		var current = redo_history.pop_back()
#		image.load_png_from_buffer(current)
		unpack_frames(current)
#		undo_history.push_back(image.save_png_to_buffer())
#		undo_history.push_back(pack_frames())
		undo_history.push_back(current)
		sync_image()
		sync_dimensions()

func update_history(clear_redo := true):
	
	undo_history.append(pack_frames())
#	undo_history.append(image.save_png_to_buffer())
	if clear_redo:
		redo_history.clear()
#	print(undo_history)


func get_brush_node():
	for brush in Brush_list.get_children():
		brush = brush as TextureRect
		if brush.get_child(0).pressed:
			return brush


func get_brush_pixels(pos := Vector2(), start_pos := Vector2(), end_pos := Vector2()) -> Dictionary:
	var node := current_brush
	var pixels := {}
	if node.has_meta("function"):
		if Brush_size.value <= 1:
			return {pos: Color.white}
		
		var function = node.get_meta("function")
		var size = Brush_size.value - 1
		var radius = Vector2.RIGHT.rotated(deg2rad(Brush_angle.value)) * (size/2.0)
		if function != "paint_line":
			radius = Vector2.ONE * size/2.0
		
		var sp =  (pos - radius).round()
		var ep = (pos + radius).round()
		var pixel_list: Array = call(function, sp, ep)
		if function == "paint_line":
			if !start_pos.is_equal_approx(end_pos):
				for i in pixel_list.size():
					if i == pixel_list.size()-1:
						continue
					
					var pixel = pixel_list[i]
					if start_pos.x > end_pos.x:
						pixel_list.append(pixel + Vector2.LEFT)
					else:
						pixel_list.append(pixel + Vector2.RIGHT)
			
#		for pixel in call(function, pos, pos + (Vector2.ONE * (size - 1))):
		for pixel in pixel_list:
			pixels[pixel] = Color.white
	else:
		var img: Image = node.texture.image
		var rct := img.get_used_rect()
		img.lock()
		for x in range(rct.position.x, rct.end.x):
			for y in range(rct.position.y, rct.end.y):
				pixels[Vector2(x, y) + pos] = img.get_pixel(x, y)
		img.unlock()

	return pixels
	

func line_brush():
	pass

func circle_brush():
	pass

func rect_brush():
	pass


func add_stamp(pixels, size = Vector2()):
	var maximum := Vector2()
	for pixel in pixels:
		maximum.x = max(maximum.x, pixel.x)
		maximum.y = max(maximum.y, pixel.y)
	if size:
		maximum = size
	
	var tex_rct := stamp_scene.instance()
	
	var img := Image.new()
	var img_rect := Rect2(Vector2(), maximum + Vector2.ONE)
	img.create(img_rect.size.x, img_rect.size.y, false, get_image().get_format())
	
	img.fill(Color(0,0,0,0))
	img.lock()
	var is_dict = pixels is Dictionary
	for pixel in pixels:
		var col = Color.white
		if is_dict:
			col = pixels[pixel]
		if img_rect.has_point(pixel):
			img.set_pixelv(pixel, col)
	img.unlock()
	
	tex_rct.texture = ImageTexture.new()
	tex_rct.texture.image = img
	tex_rct.rect_min_size = Vector2.ONE * 16
	
#	tex_rct.set_meta("pixels", pixels)
	tex_rct.set_meta("pixels", pixels)
	tex_rct.get_child(0).connect("pressed", self, "on_stamp_pressed", [tex_rct])
	
	Brush_list.add_child(tex_rct)
	return tex_rct


func on_stamp_pressed(node):
	current_brush = node
	var points = node.get_meta("pixels")
	var size := Vector2.ONE
	for stamp in Brush_list.get_children():
		stamp.get_child(0).pressed = stamp == node
	var pixels := {}
	if points is Dictionary:
		pixels = points
	else:
		for point in points:
			size.x = max(size.x, point.x)
			size.y = max(size.y, point.y)
			pixels[point] = Color.white
	stamp_pixels = pixels
	
	_on_BrushSize_value_changed(Brush_size.value)
#	update_cursor(pixels, Brush_size.value * Vector2.ONE)


func update_cursor(pixels, size := Vector2.ONE):
	var img = Image.new()
	img.create(size.x + 1, size.y + 1, false, get_image().get_format())
	
	if size.length() > 1:
		img.fill(Color(0,0,0,0))
		for point in pixels:
			
			if point.x >= size.x: continue
			if point.y >= size.y: continue
			if point.x < 0: continue
			if point.y < 0: continue
			var col = Color.white
			if pixels is Dictionary:
				col = pixels[point]
			img.lock()
			img.set_pixelv(point, col)
			img.unlock()
	else:
		img.fill(Color.white)
	
	
	$Cursor.texture.image = img
	$Cursor.update()


func choose_modifiers(arr := default_modifiers):
	for child in Modifier_container.get_children():
		child.visible = child in arr


func sync_dimensions():
	Canvas_height.value = get_image().get_height()
	Canvas_width.value = get_image().get_width()

func get_frame(): return Table_container.selected_frame
func get_layer(): return Table_container.selected_layer
func get_layer_visible(layer): return Table_container.get_layer_visible(layer)


func get_image() -> Image:
	return frames[get_frame()][get_layer()]

func sync_image(target_image := get_image()):
#	frames[get_frame()][get_layer()] = image

	var tex: Image = target_image.duplicate()
	tex.fill(Color(0,0,0,0))
#	var created = false
#	var layer := -1
	
#	var img_frame = tex.duplicate()
	var icon := tex.duplicate()
	var frame_count = Table_container.get_frame_count()
	var layer_count = Table_container.get_layer_count()
	var f_delete = -1
	for i in max(frames.size(), frame_count):
		if i >= frame_count:
			Table_container.add_frame()
		if i >= frames.size():
			if f_delete < 0:
				f_delete = i
			Table_container.delete_frame(f_delete)
			continue
		
		var l_delete = -1
		var img_frame = tex.duplicate()
#		img_frame
		for j in max(frames[i].size(), layer_count):
			if j >= layer_count:
				Table_container.add_layer()
			if j >= frames[i].size():
				if l_delete < 0:
					l_delete = j
				Table_container.delete_layer(l_delete)
				continue
			
			if !get_layer_visible(j): continue
			
			var img_layer = frames[i][j]
			if i == get_frame():
				if j != get_layer():
					Table_container.call("set_layer_image", img_layer, j)
#					Table_container.call_deferred("set_layer_image", img_layer, j)
				else:
					Table_container.call("set_layer_image", target_image, j)
#					Table_container.call_deferred("set_layer_image", target_image, j)
					pass
			
			if j == get_layer() and i == get_frame():
				img_frame.blend_rect(target_image, Rect2(Vector2(), target_image.get_size()), Vector2())
			else:
				img_frame.blend_rect(img_layer, Rect2(Vector2(), target_image.get_size()), Vector2())
#				Table_container.call_deferred("set_layer_image", img_layer, j)
		
#		Table_container.set_frame_image(img_frame.duplicate(), i)
		if i == get_frame():
			icon = img_frame.duplicate()
#		else:
#		print('o ', i)
		Table_container.call_deferred("set_frame_image", img_frame.duplicate(), i)
#			print(i)
	
#	for img in frames[get_frame()]:
#		layer += 1
#
#		Table_container.call_deferred("set_layer_image", img, layer)
#		if get_layer_visible(layer):
#			if layer == get_layer():
#				tex.blend_rect(target_image, Rect2(Vector2(), target_image.get_size()), Vector2())
#			else:
#				tex.blend_rect(img, Rect2(Vector2(), target_image.get_size()), Vector2())
				
#	tex.blend_rect(overlay, Rect2(Vector2(), target_image.get_size()), Vector2())
	texture.image = icon
	$TiledTexture.refresh(icon)
	
#	texture.image = target_image
#	overlay = target_image.duplicate()



#func _draw():
	
	
#	print(frames)
#
##	draw_texture(image, Vector2())
#	for img in frames[Table_container.selected_frame]:
#		var tex = ImageTexture.new()
#		tex.create_from_image(img)
#		draw_texture(tex, Vector2())


#func _input(event):
#	mouse_filter = Control.MOUSE_FILTER_IGNORE


func gui_input(raw_event):
#	mouse_filter = Control.MOUSE_FILTER_PASS
	if !ready: return
	navigation(raw_event)
	
	if raw_event is InputEventMouse:
		var event = raw_event.duplicate()
		var pos = (event.position - rect_position) / rect_scale.x
#		pos.x *= get_image().get_width() / rect_size.x
#		pos.y *= get_image().get_height() / rect_size.y
		event.position = pos.floor()
		
		if event is InputEventMouseButton and event.button_index in [BUTTON_LEFT, BUTTON_RIGHT]:
			pressed = event.pressed
			if event.pressed:
				press_pos = event.position
				previous_pos = event.position
				brush_path.clear()
#				pencil_image = get_image().duplicate()
		
		var limit := get_image_rect()
		if !selection.empty():
			limit = selection_rect
		
		if Input.is_mouse_button_pressed(BUTTON_RIGHT):
			current_color = right_color
		elif Input.is_mouse_button_pressed(BUTTON_LEFT):
			current_color = left_color
		
		
		handle_drag(event, "paint_" + override_tool, current_color, limit)
		if frame_just_selected >= 0:
			press_pos = event.position
			previous_pos = event.position
			brush_path.clear()
#			pencil_image = get_image().duplicate()
			frame_just_selected = -1
			
#			print("frame switch")
		previous_pos = event.position
	
#	update()
	


func navigation(event):
	if !host: return
	
	if !selection.empty():
		handle_cut()
	handle_override_tool(event)
	
	if Input.is_key_pressed(KEY_SPACE):
		rect_position += get_global_mouse_position() - previous_mouse_pos
	previous_mouse_pos = get_global_mouse_position()
	
	if event is InputEventMouse:
		if event.is_pressed():
			var scroll = int(event.button_index == BUTTON_WHEEL_UP) - int(event.button_index == BUTTON_WHEEL_DOWN)
			if scroll != 0:
				zoom(scroll)
				Canvas_overrider.emit_signal("resized")
	Canvas_overrider.rect_scale = rect_scale
	Canvas_overrider.rect_global_position = rect_global_position

func zoom(scroll, global_mouse: Vector2 = get_global_mouse_position()):
#	var global_mouse := get_global_mouse_position()
	var loc_mouse: Vector2 = global_mouse - rect_global_position
	var pixel := loc_mouse / rect_scale.x

	rect_scale += scroll * Vector2.ONE * .1 * rect_scale.x
	rect_global_position = -(pixel*rect_scale.x - global_mouse)


func handle_drag(event: InputEventMouse, method := "paint_line", color: Color = left_color, limit := get_image_rect()):
	if !has_method(method): return
	
	var start_pos = press_pos.floor()
	var end_pos = event.position.floor()
	var base_color: Color = color
	
	if Snap_check.pressed:
		var snap_result = handle_snap(start_pos, end_pos)
		start_pos = snap_result[0]
		end_pos = snap_result[1]
	
	released = (event is InputEventMouseButton 
		and !event.pressed 
		and event.button_index in [BUTTON_LEFT, BUTTON_RIGHT])
	
	if Selection_handler.visible:
		previous_pos -= Selection_handler.get_pos()
		start_pos -= Selection_handler.get_pos()
		end_pos -= Selection_handler.get_pos()
		limit = Selection_handler.get_image_rect()
	
	var is_selection_handling := false
	var stamp = get_brush_pixels(Vector2(), start_pos, end_pos)
#	var stamp = {Vector2(): Color.white}
	var target_image: Image = get_image()
	if !pressed and !released:
		target_image = null
	elif Selection_handler.visible:
#		target_image = Selection_handler.get_image_transformed()
		Selection_handler.transform_image()
		target_image = Selection_handler.image
		is_selection_handling = true
	
	if released:
#		target_image = image
#		target_image = frames[get_frame()][get_layer()]
		pass
	if pressed: # held
		if frame_just_selected >= 0:
			target_image = frames[frame_just_selected][get_layer()]
		else:
			target_image = target_image.duplicate()
		
		
		var diff = (start_pos - end_pos).abs()
		if (diff.x * diff.y)*stamp.size() > 15000:
			method = method.replace("_fill", "")
	
	var hflip = Flip_horizontal.pressed
	var vflip = Flip_vertical.pressed
	var center = vect_to_pair(limit.position + limit.size/2.0)
	
	var any_change = false
	if target_image != null:
		var pixels = call(method, start_pos, end_pos)
		var is_dict = pixels is Dictionary
		if target_image.get_data().size() == 0: return
		target_image.lock()
		
		for pixel in pixels:
			var flips := {}
			var bunch = stamp
			
			if "fill" in method: # Really cool effect with brush. Explore
				if (
					(!(pixel.x in [start_pos.x, end_pos.x]) and !(pixel.y in [start_pos.y, end_pos.y]))
					or "floodfill" in method
					):
					bunch = {Vector2(): Color.black}
			
			for p in bunch:
				var col = base_color
				if is_dict:
					col = bunch[p]
				
				p += pixel
				flips[p] = col
				var relative = p - center
				if hflip:
					flips[Vector2(center.x - relative.x-.5, p.y)] = col
				if vflip:
					flips[Vector2(p.x, center.y - relative.y-.5)] = col
				if hflip and vflip:
					flips[Vector2(center.x - relative.x-.5, center.y - relative.y-.5)] = col
			
			for p in flips.keys():
				var old_p = p
				if Tiled_wrapped.pressed:
					p.x = wrapi(p.x, limit.position.x, limit.end.x)
					p.y = wrapi(p.y, limit.position.y, limit.end.y)
				if !limit.has_point(p):
					continue
#				if !flips.has(p):
#					continue
				var col = flips[old_p]
#				 base_color.blend(flips[p])
#				if is_dict:
#					col = flips[p]
				target_image.set_pixelv(p, col)
				any_change = true
		
		target_image.unlock()
		if !is_selection_handling:
#			texture.image = target_image
			sync_image(target_image)
			pass
		else:
			Selection_handler.update_image(target_image)
		
		if released and any_change:
			update_history()
	return


func handle_snap(start_pos, end_pos):
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
	
	return [start_pos, end_pos]


func handle_cut():
	if (true
#		and current_tool == "selection"
		and !selection.empty() 
		and Input.is_key_pressed(KEY_CONTROL) 
		and Input.is_key_pressed(KEY_X)
	):
		Selection_handler.visible = false
		stamp_pixels.clear()
		var origin = get_local_mouse_position()
		var img = Selection_handler.get_image()
		var rct = img.get_used_rect()
		img.lock()
		for x in range(rct.position.x, rct.end.x):
			for y in range(rct.position.y, rct.end.y):
				stamp_pixels[Vector2(x, y)] = img.get_pixel(x, y)
#			img.set_pixelv(pixel, Color(0,0,0,0))
		img.unlock()
#		sync_image()
#		texture.image = image
		current_tool = "stamp"
		highlight_current_tool()
		selection.clear()
#		update_history()
		
		
		var stamp = add_stamp(stamp_pixels)
		stamp.get_child(0).pressed = true
		stamp.get_child(0).emit_signal("pressed")
		


func handle_override_tool(event):
	var key_map := {
		KEY_B: "brush",
		KEY_C: "circle",
		KEY_R: "rect",
		KEY_E: "ellipse",
		KEY_M: "selection",
		KEY_F: "floodfill",
		KEY_L: "line",
	}
	
#	override_tool = current_tool
	
	if event is InputEventKey:
		for key in key_map:
			if (event.pressed
			and !event.echo
			and event.scancode == key):
				var label = key_map[key]
				if event.shift and has_method("paint_" + label + "_fill"):
					label += "_fill"
				if event.control and has_method("paint_" + label + "_aspect"):
					label += "_aspect"
#				print(label)
				current_tool = label
		
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
#						update()
					
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
	
	Selection_handler.set_draggable(override_tool == "selection")


func highlight_current_tool(val = current_tool):
	val = val.replace("_fill", "")
	val = val.replace("_aspect", "")
	Tool_container.highlight_tool(val)
	return

func highlight_current_colors():
	Color_left.color = left_color
	Color_right.color = right_color



func paint_stamp(start_pos: Vector2, end_pos: Vector2):
#	var pixels := {}
#	for pixel in get_brush_pixels():
#		var color: Color = stamp_pixels[pixel]
#
#		if color == Color(0,0,0,0): continue
#
#		var pos = pixel + end_pos
#		pixels[vect_to_pair(pos)] = color
	return {end_pos: Color.white}


func paint_brush(a, pos: Vector2):
	var pixels = paint_line(previous_pos, pos)
	for pixel in pixels:
		if !brush_path.has(pixel):
			brush_path.append(pixel)
	if Pixel_perfect.pressed:
		pixel_perfect()
	return brush_path


func pixel_perfect(target := brush_path):
#	var i = brush_path.size() - 1
	for c in target.size():
		var i = target.size() - 1 - c
		if i + 1 >= target.size(): continue
		if i - 1 < 0: continue
		
		if ((target[i-1].x == target[i].x or target[i-1].y == target[i].y)
		and (target[i+1].x == target[i].x or target[i+1].y == target[i].y)
		and (target[i+1].x != target[i-1].x)
		and (target[i+1].y != target[i-1].y)
			):
			target.remove(i)
	
	return target


func paint_line(start_pos: Vector2, end_pos: Vector2) -> Array:
	var pixels := []
	var rect = points_to_rect(start_pos, end_pos)
	
	if start_pos == end_pos: 
		if not start_pos in pixels:
			pixels.append(start_pos)
	else:
		var diff := end_pos - start_pos
		var maxim: float = max(max(rect.size.x, rect.size.y), 1)
		
		var aspect = diff
		aspect.x /= maxim
		aspect.y /= maxim
		for i in range(maxim + 1):
			var pos = aspect * i
			pos += start_pos
			if not pos.round() in pixels:
				pixels.append(vect_to_pair(pos))
	
	return pixels

#func point_to_brush(pos: Vector2):
#	pass

func aspect_end_pos(start_pos, end_pos) -> Vector2:
	var diff = (end_pos - start_pos)
	var r = max(diff.abs().x, diff.abs().y)
	end_pos = start_pos + diff.sign()*r
	return end_pos


func paint_rect_aspect(start_pos: Vector2, end_pos: Vector2):
	return paint_rect(start_pos, aspect_end_pos(start_pos, end_pos))
	

func paint_rect_fill_aspect(start_pos: Vector2, end_pos: Vector2):
	return paint_rect_fill(start_pos, aspect_end_pos(start_pos, end_pos))


func paint_rect(start_pos: Vector2, end_pos: Vector2) -> Array:
	var pixels := []
	var rect = points_to_rect(start_pos, end_pos)
	rect = rect.clip(get_image_rect().grow(1.0))
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
	var rect: Rect2 = points_to_rect(start_pos, end_pos)
#	rect = rect.clip(get_image_rect().grow(8.0))
	
	var clip = rect.clip(get_image_rect())
#	clip = rect
	
#	pixels += fill(rect.position + rect.size/2.0, paint_rect(start_pos, end_pos), rect)
	
	for i in range(rect.position.x, rect.end.x + 1):
		for j in range(rect.position.y, rect.end.y + 1):
			var pixel = vect_to_pair(Vector2(i,j))
			if !clip.has_point(pixel): continue
			pixels.append( pixel )
	return pixels


func paint_ellipse_aspect(start_pos: Vector2, end_pos: Vector2) -> Array:
	return paint_ellipse(start_pos, aspect_end_pos(start_pos, end_pos))


func paint_ellipse_fill_aspect(start_pos: Vector2, end_pos: Vector2) -> Array:
	return paint_ellipse_fill(start_pos, aspect_end_pos(start_pos, end_pos))
#
#	var pixels := []
#	var rect := points_to_rect(start_pos, end_pos)
#	var radius = rect.size.length()
#	var circle_rect = Rect2(start_pos, Vector2()).grow(radius)
#
#	for x in range(circle_rect.position.x, 1+circle_rect.position.x + circle_rect.size.x):
#		for y in range(circle_rect.position.y, 1+circle_rect.position.y + circle_rect.size.y):
#			var pos = Vector2(x,y)
#			if (pos - start_pos).abs().length() < radius:
#				pixels.append(vect_to_pair(pos))
#
#	return pixels


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

#func nfloor(n):
#	return floor(abs(n)) * sign(n)
#func nround(n):
#	return round(abs(n)) * sign(n)
#func nceil(n):
#	return ceil(abs(n)) * sign(n)


func paint_ellipse_fill(start_pos: Vector2, end_pos: Vector2) -> Array:
	if start_pos.is_equal_approx(end_pos):
		return[end_pos]
	var rect: Rect2 = points_to_rect(start_pos, end_pos)
	if rect.has_no_area():
		return[end_pos]
		
	rect.end += Vector2.ONE
#	print(rect)
	var pixels := []
	var center = rect.position + rect.size/2.0
	var radius: Vector2 = (rect.size) / 2.0
#	radius = radius.round()
	
#	var increment := 1
#	var pos = center + Vector2.RIGHT*radius.x
	
	
#	for x in range(center.x + nfloor(-radius.x), center.x + nfloor(radius.x) + 1):
#		x = float(x)
#		var h: float = x + 0.5
#		var ydiff = sqrt( (1 - (pow(h - center.x, 2)/pow(radius.x, 2)) ) * pow(radius.y, 2) )
##		ydiff = floor(abs(ydiff))
##		ydiff = nfloor(ydiff)
#		var ys = range(center.y + nceil(-ydiff), center.y + nfloor(ydiff) + 1)
#		for y in ys:
#
#			pixels.append(Vector2((h-.5), y).round())
		
#		ydiff = (round(ydiff))
#		print("ydiff", ydiff)
##		pixels.append_array(range((center.y - ydiff), (center.y + ydiff)))
#		for y in range((center.y - ydiff), (center.y + ydiff) + 1):
##			y += center.y
#			y = round(y-.5)
#
#			print("center ", center)
#			print("y ", y)
#			pixels.append(Vector2(x, y))
	
	for x in range(rect.position.x, rect.end.x + 1):
		for y in range(rect.position.y, rect.end.y + 1):
			var p = Vector2(x,y) + Vector2.ONE*.5
			var ellipse_calc = pow((p.x-center.x),2)/pow(radius.x,2) + pow((p.y-center.y),2)/pow(radius.y,2)
			var dist: Vector2 = p - center
			dist = dist.abs()
			
			
			var dir = Vector2(
				dist.x / radius.x,
				dist.y / radius.y
			).normalized()
			
			dir.x *= radius.x
			dir.y *= radius.y
			
#			if dist.length_squared() < dir.length_squared():
			if ellipse_calc < 1:
				pixels.append(Vector2(x,y))
	return pixels
	
#	for i in range(0, 360 + increment, increment):
#		var dir := Vector2.RIGHT.rotated(deg2rad(i))
#		dir.x *= radius.x
#		dir.y *= radius.y
#		pixels.append_array(paint_line(pos, center+dir))
#		pos = center + dir
#
#	var outline := paint_ellipse(start_pos, end_pos)

#	var pixels = outline + fill(rect.position + rect.size / 2.0, outline, rect)
#	return pixels


func paint_selection(start_pos: Vector2, end_pos: Vector2):
	var _image: Image = get_image()
#	if Selection_handler.visible or !selection.empty():
#		place_pixels_from_selection()
#		Selection_handler.visible = false
	if Selection_handler.visible and !selection.empty():
		place_pixels_from_selection()
		Selection_handler.visible = false
		selection.clear()
		selection_rect = Rect2()
#		return []
	
	if start_pos.is_equal_approx(end_pos): 
		selection.clear()
		Selection_handler.visible = false
		selection_rect = Rect2()
		return []
	
	var rect := points_to_rect(start_pos, end_pos).grow_individual(0,0,1,1)
	selection.clear()
	var limits := get_image_rect()
	selection_rect = rect.clip(limits)
	
	if !selection_rect.has_no_area(): 
		for x in range(rect.position.x, rect.end.x + 1):
			for y in range(rect.position.y, rect.end.y + 1):
				var pos := vect_to_pair(Vector2(x,y))
				if !limits.has_point(pos): continue
				selection.append(pos)
		$SelectionDrawer.update()
		if released:
#			print(selection_rect)
			transfer_pixels_to_selection()
	else:
		Selection_handler.visible = false
#		sync_image()
	
	return []


func transfer_pixels_to_selection():
	var img := Image.new()
	img.create(selection_rect.size.x, selection_rect.size.y, false, get_image().get_format())
	img.fill(Color(0,0,0,0))
	img.blit_rect(get_image(), selection_rect, Vector2())
	Selection_handler.visible = true
	Selection_handler.set_image(img)
	Selection_handler.set_pos(selection_rect.position)
	Selection_handler.set_selection_size(selection_rect.size)
	
	var _image = get_image()
	_image.lock()
	for point in selection:
		if selection_rect.has_point(point):
			_image.set_pixelv(point, Color(0,0,0,0))
	_image.unlock()
	sync_image()
#	update_history()


func place_pixels_from_selection():
	get_image().blend_rect(Selection_handler.get_image(), Selection_handler.get_image_rect(), Selection_handler.get_pos())
	sync_image()
	update_history()


func paint_color_pick(spos: Vector2, epos: Vector2):
	var col := Color(0,0,0,0)
	if get_image_rect().has_point(epos): 
		get_image().lock()
		col = get_image().get_pixelv(epos)
		get_image().unlock()
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		left_color = col
		highlight_current_colors()
	elif Input.is_mouse_button_pressed(BUTTON_RIGHT):
		right_color = col
		highlight_current_colors()
	
	return []


func paint_floodfill(start_pos, end_pos):
	var limits := get_image_rect()
	if !limits.has_point(end_pos): return []
	var drag_rect = points_to_rect(start_pos, end_pos)
	
	var result := []
	var border := []
	var img = get_image()
	img.lock()
	var color = img.get_pixelv(end_pos)
	for x in range(limits.position.x, limits.end.x):
		for y in range(limits.position.y, limits.end.y):
			var pos = vect_to_pair(Vector2(x,y))
			var col = img.get_pixel(x,y)
			if !col.is_equal_approx(color):
				border.append(pos)
	img.unlock()
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
	return Rect2(Vector2(), get_image().get_size())


#func add_modifier():
#	for child in Modifier:
#		child.queue_free()
	
	


func _on_ColorPickerButton_color_changed(col):
	left_color = col

func _on_ColorPickerButtonRight_color_changed(col):
	right_color = col


func _on_GridContainer_tool_selected(node: Node):
	if node is Button:
		current_tool = node.text.to_lower()
		var mods = default_modifiers + []
		match current_tool:
			"brush":
				mods += [Pixel_perfect]
			"selection":
				mods += [Selection_controls]
		choose_modifiers(mods)


func _on_SpinBox_value_changed(value):
	brush_size = value


func _on_Width_value_changed(value):
	set_dimensions(value, get_image().get_height())

func _on_Height_value_changed(value):
	set_dimensions(get_image().get_width(), value)

func set_dimensions(width, height):
	var pos = rect_position
	var scale = rect_scale
	
	
	for frm in frames:
		for lyr in frm:
			if Canvas_resize_mode.selected == 0:
				lyr.crop(width, height)
			else:
				lyr.resize(width, height, Canvas_resize_mode.selected - 1)
#	match Canvas_resize_mode.selected:
#		0:
#			image.crop(width, height)
#		1:
#			image.resize(width, height, Image.INTERPOLATE_NEAREST)
#		2:
#			image.resize(width, height, Image.INTERPOLATE_BILINEAR)
#		3:
#			image.resize(width, height, Image.INTERPOLATE_CUBIC)
#		4:
#			image.resize(width, height, Image.INTERPOLATE_TRILINEAR)
#		5:
#			image.resize(width, height, Image.INTERPOLATE_LANCZOS)
	
	sync_image()
	update_history()
	$GridDrawer.update()
	
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
	$GridDrawer.update()


func _on_grid_Height_value_changed(value):
	grid_size.y = value
	$GridDrawer.update()


func _on_CheckBox_toggled(button_pressed):
	$GridDrawer.update()


func _on_Table_frame_added():
#	frames.append( frames.back().duplicate(true) )
#	print()
#	print(frames.size())
	var result = []
	for layer in frames.back():
		var img = layer.duplicate()
#		img.fill(Color(0,0,0,0))
		result.append(img)
	frames.append(result)
#	print(frames.size())
	sync_image()
	update_history()
#	print(frames)


func _on_Table_layer_added():
	for layer in frames:
		var img = image.duplicate()
		img.fill(Color(0,0,0,0))
		layer.append( img )
	sync_image()
	update_history()
#	print(frames)


func _on_Table_visibility_pressed():
	call_deferred("sync_image")


func _on_Table_layer_removed(id):
	for frame in frames:
		frame.remove(id)
	sync_image()
	update_history()

func _on_Table_frame_removed(id):
#	print()
#	print(frames.size())
	frames.remove(id)
#	print(frames.size())
#	yield(get_tree(), "idle_frame")
#	print(frames)
	sync_image()
	update_history()


func delete_layer(id):
	_on_Table_layer_removed(id)
func delete_frame(id):
	_on_Table_frame_removed(id)

func move_frame(source, destination):
	
	var temp = frames[source].duplicate()
	frames.insert(destination, temp)
	if destination < source:
		source += 1
	frames.remove(source)
	sync_image()
	update_history()

func move_layer(source, destination):
	for layers in frames:
		var temp = layers[source].duplicate()
		layers.insert(destination, temp)
		if destination < source:
			source += 1
		layers.remove(source)
	
	sync_image()
	update_history()


func _on_Table_frame_selected():
#	frame_just_selected = true
	sync_image()
#	print("selected", get_frame())


func _on_Table_anim_frame_changed(frame):
#	print("received signal ", frame)
#	place_pixels_from_selection()
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		warp_mouse(get_local_mouse_position())
	frame_just_selected = frame
#	print('rexe')


func _on_HideSettings_toggled(button_pressed):
	Right_panel.visible = button_pressed


func _on_HideTools_toggled(button_pressed):
	Left_panel.visible = button_pressed


func _on_HideFrames_toggled(button_pressed):
	Table_container.visible = button_pressed


func _on_Table_frame_moved(source, destination):
	move_frame(source, destination)


func _on_Table_layer_moved(source, destination):
	move_layer(source, destination)


func get_parent_center():
	return get_parent_control().rect_global_position + get_parent_control().rect_size/2.0
func get_canvas_center():
	return Canvas_area.rect_global_position + Canvas_area.rect_size*0.5
func recenter_image():
	rect_global_position = get_canvas_center() - (rect_size*rect_scale*0.5)
#	rect_global_position = get_parent_center() - rect_size/2.0

func _on_ZoomIn_pressed():
	zoom(-4, get_canvas_center())
	pass # Replace with function body.


func _on_ZoomOut_pressed():
	zoom(4, get_canvas_center())
	pass # Replace with function body.


func _on_ZoomReset_pressed():
	rect_scale = Vector2.ONE
	recenter_image()


func _on_FitHeight_pressed():
	var c_size = Canvas_area.rect_size
	rect_scale = c_size.y / get_image().get_height() * Vector2.ONE
	recenter_image()


func _on_Center_pressed():
	recenter_image()


func _on_BrushSize_value_changed(value):
	update_cursor(get_brush_pixels(), value*Vector2.ONE)


func _on_SaveAnimatedFrame_pressed():
	save_animated_texture()
