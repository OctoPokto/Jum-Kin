extends Control

@onready var content = get_node("Content")
@onready var typing_timer = get_node("TypingTimer") as Timer

@onready var target: Vector2

func _ready() -> void:
	visible = false
	await get_tree().create_timer(2.0).timeout
	typing_timer.timeout.connect(_on_TypingTimer_timeout)
	update_message("Oh it's recording now? What do you want me to say?", target)
	
func update_message(message: String, target: Vector2)-> void:
	content.text = message
	set_position(target)
	await get_tree().create_timer(2.0).timeout
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
