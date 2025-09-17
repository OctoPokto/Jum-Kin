extends Control

@onready var content = get_node("Content") as RichTextLabel
@onready var typing_timer = get_node("TypingTimer") as Timer

func _ready() -> void:
	visible = false
	await get_tree().create_timer(2.0).timeout
	typing_timer.timeout.connect(_on_TypingTimer_timeout)
	#update_message("Oh it's recording now? What do you want me to say?", target)
	
func update_message(message: String, target: Vector2, color: Color)-> void:
	
	print("Entered update message")
	var parent_ci := get_parent() as CanvasItem
	var local_pos := target
	if parent_ci:
		var to_parent := parent_ci.get_global_transform_with_canvas().affine_inverse()
		local_pos = to_parent.basis_xform(target)
		print(local_pos)
		
	content.text = message
	content.add_theme_color_override("default_col", color)
	
	position = (local_pos + Vector2(0,50))
	await get_tree().create_timer(0.5).timeout
	content.visible_characters = 0
	visible = true
	typing_timer.start()
	

func _on_TypingTimer_timeout()->void:
	if content.visible_characters < content.text.length():
		content.visible_characters +=1
		print("a character is displayed")
	else:
		typing_timer.stop()
		await get_tree().create_timer(2.0).timeout
		visible = false
		content.text = ""
