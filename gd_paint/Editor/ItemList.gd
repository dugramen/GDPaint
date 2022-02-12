tool
extends ItemList

signal tool_selected




func _on_ItemList_item_selected(index):
	emit_signal("tool_selected", get_item_text(index))
#	print('tooled  ', index)
