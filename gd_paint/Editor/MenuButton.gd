tool
extends MenuButton

func _enter_tree():
	get_popup().connect("id_pressed", self, "on_pressed")


func on_pressed(id):
	var index = get_popup().get_item_index(id)
	text = get_popup().get_item_text(index)
