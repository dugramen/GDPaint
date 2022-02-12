extends Button



func _on_SaveAs_pressed():
	$FileDialog.set_as_minsize()
	$FileDialog.popup_centered_ratio()
