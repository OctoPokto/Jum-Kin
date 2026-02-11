extends Control

func toggle_visibility(object):
	if object.visible == true:
		object.visible = false
		get_tree().paused = false
		print(get_tree().paused)

	else:
		object.visible = true
		get_tree().paused = true
		print(get_tree().paused)

func _exit_game() -> void:
	get_tree().quit()

func _toggle_visibility() -> void:
	var thisNode = get_node(get_path())
	toggle_visibility(thisNode)
