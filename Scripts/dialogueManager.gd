extends Control

@onready var content = get_node("Content")
@onready var typing_timer = get_node("TypingTimer") as Timer

var target

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	typing_timer.timeout.connect(_on_TypingTimer_timeout)
	update_message("Oh it's recording now? What do you want me to say?")
	
func update_message(message: String)-> void:
	content.text = message
	await get_tree().create_timer(2.0).timeout
	content.visible_characters = 0
	print("No visible characters")
	typing_timer.start()
	
func _on_TypingTimer_timeout()->void:
	if content.visible_characters < content.text.length():
		content.visible_characters +=1
		print("a character is displayed")
	else:
		typing_timer.stop()
