extends Control

@onready var content: RichTextLabel = get_node("Content")
@onready var typing_timer: Timer = get_node("TypingTimer")

@export var pre_delay_sec: float = 0.05
@export var post_hold_sec: float = 2.0
@export var screen_offset: Vector2 = Vector2(0, 50)

signal line_finished(id: int)

var _queue: Array[Dictionary] = []
var _busy := false
var _next_id := 1
var _current_id := 0

func _ready() -> void:
	visible = false
	typing_timer.timeout.connect(_on_TypingTimer_timeout)

func update_message(message: String, world_target: Vector2, color: Color) -> void:
	_enqueue(message, world_target, color)
	_try_start()

func say_and_wait(message: String, world_target: Vector2, color: Color) -> void:
	var id := _enqueue(message, world_target, color)
	_try_start()
	while true:
		var got_id: int = await line_finished
		if got_id == id:
			break

func _enqueue(msg: String, world_pos: Vector2, color: Color) -> int:
	var id := _next_id
	_next_id += 1
	_queue.append({
		"id": id,
		"msg": msg,
		"world": world_pos,
		"color": color
	})
	return id

func _try_start() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true

	var item: Dictionary = _queue.pop_front()
	_current_id = int(item["id"])

	var parent_ci := get_parent() as CanvasItem
	var local_pos: Vector2 = item["world"]
	if parent_ci:
		var to_parent := parent_ci.get_global_transform_with_canvas().affine_inverse()
		local_pos = to_parent.basis_xform(local_pos)
	local_pos += screen_offset

	content.add_theme_color_override("default_color", item["color"])
	content.text = String(item["msg"])
	position = local_pos

	await get_tree().create_timer(pre_delay_sec).timeout
	content.visible_characters = 0
	visible = true
	typing_timer.start()

func _on_TypingTimer_timeout() -> void:
	if content.visible_characters < content.text.length():
		content.visible_characters += 1
	else:
		typing_timer.stop()
		await get_tree().create_timer(post_hold_sec).timeout
		visible = false
		content.text = ""
		var finished_id := _current_id
		_current_id = 0
		_busy = false
		line_finished.emit(finished_id)
		_try_start()
