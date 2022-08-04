tool
extends VBoxContainer

signal value_changed(value)


export var value := 1.0 setget set_value, get_value
export var wrapping := false


func set_value(val):
	
	$SpinBox.value = val
	value = $SpinBox.value
func get_value():
	return $SpinBox.value




func _ready():
	$SpinBox.share($HSlider)



func _on_SpinBox_value_changed(val):
	value = val
	emit_signal("value_changed", val)
