extends Control

@onready var bubble: MarginContainer  = $Bubble
@onready var content: RichTextLabel   = $Bubble/Content
@onready var typing_timer: Timer      = $TypingTimer
@onready var ninepatch: NinePatchRect = get_node_or_null("NinePatchRect") as NinePatchRect

@export var pre_delay_sec: float = 0.05
@export var post_hold_sec: float = 2.0
@export var screen_offset: Vector2 = Vector2(0, 50)
@export var screen_margin: float = 16.0
@export var max_content_width: float = 320.0
@export var clamp_vertical: bool = true
@export var min_target_gap: float = 10.0
@export var prefer_above: bool = false
@export var bg_extra_padding: Vector2 = Vector2(8, 4)

signal line_finished(id: int)

var _queue: Array[Dictionary] = []
var _busy: bool = false
var _next_id: int = 1
var _current_id: int = 0

var _anchor_ui: Vector2 = Vector2.ZERO
const SIDE_ABOVE: int = -1
const SIDE_BELOW: int = 1
var _locked_side_y: int = SIDE_BELOW

func _ready() -> void:
	visible = false
	typing_timer.timeout.connect(_on_TypingTimer_timeout)

func update_message(message: String, world_target: Vector2, color: Color) -> void:
	var _id: int = _enqueue(message, world_target, color)
	_try_start()

func say_and_wait(message: String, world_target: Vector2, color: Color) -> void:
	var id: int = _enqueue(message, world_target, color)
	_try_start()
	while true:
		var got_id: int = await line_finished
		if got_id == id:
			break

func _enqueue(msg: String, world_pos: Vector2, color: Color) -> int:
	var id: int = _next_id
	_next_id += 1
	_queue.append({ "id": id, "msg": msg, "world": world_pos, "color": color })
	return id

func _try_start() -> void:
	if _busy or _queue.is_empty():
		return
	_busy = true

	var item: Dictionary = _queue.pop_front()
	_current_id = int(item["id"])

	var ct: Transform2D = get_viewport().get_canvas_transform()
	_anchor_ui = ct.basis_xform(item["world"]) + ct.origin

	content.add_theme_color_override("default_color", item["color"])
	content.text = String(item["msg"])
	content.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.fit_content = true

	var vp: Vector2 = get_viewport_rect().size
	var usable_w: float = max(1.0, vp.x - 2.0 * screen_margin)
	var locked_w: float = usable_w
	if max_content_width < locked_w:
		locked_w = max_content_width
	_set_bubble_width(locked_w)

	await get_tree().process_frame
	_update_bubble_height_from_text()

	_place_centered_horizontally(_anchor_ui.x + screen_offset.x)
	if clamp_vertical:
		_locked_side_y = _choose_vertical_side(_anchor_ui.y)
		_place_vertical_by_side(_anchor_ui.y, _locked_side_y)
	_clamp_inside_viewport_x_only()

	await get_tree().create_timer(pre_delay_sec).timeout
	content.visible_characters = 0
	visible = true
	typing_timer.start()

func _on_TypingTimer_timeout() -> void:
	if content.visible_characters < content.text.length():
		content.visible_characters += 1
		if _update_bubble_height_from_text() and clamp_vertical:
			_place_vertical_by_side(_anchor_ui.y, _locked_side_y)
			_clamp_inside_viewport_x_only()
	else:
		typing_timer.stop()
		await get_tree().create_timer(post_hold_sec).timeout
		visible = false
		content.text = ""
		var finished_id: int = _current_id
		_current_id = 0
		_busy = false
		line_finished.emit(finished_id)
		_try_start()

func _set_bubble_width(w: float) -> void:
	bubble.size.x = round(w)
	if ninepatch:
		ninepatch.position.x = -bg_extra_padding.x
		ninepatch.size.x = bubble.size.x + bg_extra_padding.x * 2.0

func _update_bubble_height_from_text() -> bool:
	var h: float = content.get_content_height()
	if h < 1.0:
		h = 1.0
	h = round(h)
	if bubble.size.y != h:
		bubble.size.y = h
		if ninepatch:
			ninepatch.position.y = -bg_extra_padding.y
			ninepatch.size.y = bubble.size.y + bg_extra_padding.y * 2.0
		return true
	return false

func _place_centered_horizontally(target_x: float) -> void:
	var desired_x: float = target_x - bubble.size.x * 0.5
	position.x = round(desired_x)

func _choose_vertical_side(anchor_y: float) -> int:
	var vp: Vector2 = get_viewport_rect().size
	var h: float = bubble.size.y
	var below_offset: float = (screen_offset.y if screen_offset.y > 0.0 else 0.0)
	var space_below: float = (vp.y - screen_margin) - (anchor_y + below_offset + min_target_gap)
	var space_above: float = (anchor_y - min_target_gap) - screen_margin
	var fits_below: bool = h <= space_below
	var fits_above: bool = h <= space_above
	if fits_above and fits_below:
		return (SIDE_ABOVE if prefer_above else SIDE_BELOW)
	elif fits_below:
		return SIDE_BELOW
	elif fits_above:
		return SIDE_ABOVE
	else:
		return (SIDE_BELOW if space_below >= space_above else SIDE_ABOVE)

func _place_vertical_by_side(anchor_y: float, side: int) -> void:
	var vp: Vector2 = get_viewport_rect().size
	var h: float = bubble.size.y
	var min_y: float = screen_margin
	var max_y: float = vp.y - screen_margin - h
	var desired_top: float
	if side == SIDE_BELOW:
		var offset_y: float = (screen_offset.y if screen_offset.y > 0.0 else 0.0)
		desired_top = anchor_y + offset_y + min_target_gap
	else:
		desired_top = anchor_y - min_target_gap - h
	var clamped: float = desired_top
	if clamped < min_y:
		clamped = min_y
	elif clamped > max_y:
		clamped = max_y
	position.y = round(clamped)

func _clamp_inside_viewport_x_only() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var min_x: float = screen_margin
	var max_x: float = vp.x - screen_margin - bubble.size.x
	var px: float = position.x
	if px < min_x:
		px = min_x
	elif px > max_x:
		px = max_x
	position.x = round(px)
