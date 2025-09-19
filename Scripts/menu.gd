extends Control

func toggle_visibility(object):
	if object.visible == true:
		object.visible = false
	else:
		object.visible=true

func _exit_game() -> void:
	get_tree().quit()

func _toggle_visibility() -> void:
	var thisNode = get_node(get_path())
	toggle_visibility(thisNode)
