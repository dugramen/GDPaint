extends Button




func _on_Button_pressed():
	$PopupPanel.set_as_minsize()
	$PopupPanel.popup(get_rect())
