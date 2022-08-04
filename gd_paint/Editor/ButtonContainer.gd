tool
extends GridContainer

signal tool_selected


func _ready():
	for child in get_children():
		child.text = child.name
		if child is ColorPickerButton or child is SpinBox: continue
		child.connect("pressed", self, "emit_tool", [child])


func emit_tool(node):
	for child in get_children():
		child.pressed = child == node
	emit_signal("tool_selected", node)


func highlight_tool(tool_name: String):
	for child in get_children():
		child = child as Button
		child.toggle_mode = true
		if child.name.to_lower() == tool_name.to_lower():
			child.pressed = true
		else:
			child.pressed = false
