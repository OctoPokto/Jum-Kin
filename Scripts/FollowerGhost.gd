extends Node2D
class_name FollowerGhost

# config
@export var delay_frames: int = 12
@export var back_dist: float = 22.0
@export var spread_x: float = 10.0
@export var min_back_dist: float = 10.0
@export var y_offset: float = 0.0

@export var side_switch_speed: float = 140.0
@export var follow_smooth: float = 0.35
@export var ground_y_smooth: float = 0.60
@export var air_y_smooth: float = 0.25

@export var walk_speed_scale: float = 80.0

@export var edge_margin: float = 1.0
@export var scan_max_px: float = 1024.0

@export var feet_to_origin: float = 5.0
@export var ray_up: float = 64.0
@export var ray_down: float = 192.0
@export var floor_normal_thresh: float = 0.5
@export var max_y_rise_per_frame: float = 18.0

var tint: Color = Color.WHITE
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var recorder: Node = null

@export var info: FollowerInfo

# state
var _init: bool = false
var _dir_sign: int = 1
var _side_offset: float = 0.0
var _prev_pos: Vector2 = Vector2.ZERO
var _jitter_x: float = 0.0

# platform lock from last grounded frame of the player
var _lock_left_x: float = 0.0
var _lock_right_x: float = 0.0
var _lock_feet_y: float = 0.0
var _has_lock: bool = false

func set_info(i: FollowerInfo) -> void:
	info = i
	_apply_info()

func set_tint(c: Color) -> void:
	tint = c
	if is_instance_valid(sprite):
		sprite.self_modulate = tint

func set_recorder(r: Node) -> void:
	recorder = r

func set_line_index(_i: int) -> void:
	pass

func _apply_info() -> void:
	if info == null: return
	if is_instance_valid(sprite):
		sprite.self_modulate = info.color

func _ready() -> void:
	_apply_info()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(get_instance_id()) ^ 0x9E3779B9
	_jitter_x = rng.randf_range(-spread_x, spread_x)


func _physics_process(delta: float) -> void:
	if recorder == null or not recorder.has_method("get_snapshot"):
		return
	var snap: Dictionary = recorder.call("get_snapshot", delay_frames)
	if snap.is_empty():
		return

	var p: Vector2 = snap["pos"]
	var face_left: bool = bool(snap["flip_h"])
	var player_in_air: bool = snap.has("anim") and String(snap["anim"]) == "jump"

	# direction from motion (not facing)
	var prev: Dictionary = recorder.call("get_snapshot", delay_frames + 2)
	if not prev.is_empty():
		var prev_pos: Vector2 = prev["pos"]
		var dx: float = p.x - prev_pos.x
		if dx > 0.05: _dir_sign = 1
		elif dx < -0.05: _dir_sign = -1

	# side offset
	var span: float = back_dist + _jitter_x
	if absf(span) < min_back_dist:
		span = min_back_dist
	var want_side: float = float(-_dir_sign) * span
	_side_offset = want_side if not _init else move_toward(_side_offset, want_side, side_switch_speed * delta)

	# base X
	var want_x: float = p.x + _side_offset
	var target_x: float = want_x if not _init else lerp(global_position.x, want_x, follow_smooth)

	# lock updates only while the player is grounded
	if not player_in_air:
		var floor_hit: Dictionary = _ray_floor_hit(p.x, p.y + y_offset, ray_up, ray_down)
		if not floor_hit.is_empty():
			_lock_feet_y = float(floor_hit["position"].y)
			_lock_left_x  = _scan_edge(p.x, _lock_feet_y, -1.0)
			_lock_right_x = _scan_edge(p.x, _lock_feet_y,  1.0)
			_has_lock = true

	# final X/Y
	var target_y: float
	if not player_in_air and _has_lock:
		var left: float = _lock_left_x + edge_margin
		var right: float = _lock_right_x - edge_margin
		if left > right: left = right
		target_x = lerp(global_position.x, clamp(target_x, left, right), follow_smooth)

		var floor_y: float = _lock_feet_y - feet_to_origin
		var ny: float = lerp(global_position.y, floor_y, ground_y_smooth)
		var up_cap: float = global_position.y - max_y_rise_per_frame
		if ny < up_cap: ny = up_cap
		target_y = ny
	else:
		var arc_y: float = p.y + y_offset
		var ny2: float = lerp(global_position.y, arc_y, air_y_smooth)
		var up_cap2: float = global_position.y - max_y_rise_per_frame
		if ny2 < up_cap2: ny2 = up_cap2
		target_y = ny2

	global_position = Vector2(target_x, target_y)

	# anim
	var vel: Vector2 = (global_position - _prev_pos) / max(delta, 0.0001)
	_prev_pos = global_position

	if is_instance_valid(sprite):
		if not player_in_air and _has_lock:
			var speed: float = vel.length()
			if speed > 8.0:
				sprite.play("walk")
				sprite.speed_scale = clamp(speed / walk_speed_scale, 0.5, 1.8)
			else:
				sprite.play("idle")
				sprite.speed_scale = 1.0
		else:
			sprite.animation = "jump"
			if snap.has("frame"):
				sprite.set_frame(int(snap["frame"]))
		sprite.flip_h = (vel.x < 0.0) if absf(vel.x) > 2.0 else face_left

	_init = true

# helpers

func _ray_floor_hit(x: float, around_y: float, up: float, down: float) -> Dictionary:
	var space := get_world_2d().direct_space_state
	var from_pt := Vector2(x, around_y - up)
	var to_pt   := Vector2(x, around_y + down)

	var exclude: Array = [self]
	for _i in range(8):
		var params := PhysicsRayQueryParameters2D.new()
		params.from = from_pt
		params.to = to_pt
		params.exclude = exclude
		params.collide_with_bodies = true
		params.collide_with_areas = false
		params.collision_mask = -1

		var hit: Dictionary = space.intersect_ray(params)
		if hit.is_empty():
			return {}

		var col: Object = hit["collider"]
		var n: Vector2 = hit["normal"]
		var p: Vector2 = hit["position"]

		var is_dynamic: bool = (col is CharacterBody2D) or (col is RigidBody2D) or (col is AnimatableBody2D)
		var ok_normal: bool = (n.y <= -floor_normal_thresh)
		var dy: float = p.y - around_y

		if (not is_dynamic) and ok_normal and dy >= -up and dy <= down:
			return hit

		exclude.append(col)
	return {}

func _scan_edge(start_x: float, floor_y_feet: float, dir: float) -> float:
	var x: float = start_x
	var max_px: int = int(scan_max_px)
	for _i in range(max_px):
		var nx: float = x + dir
		var h: Dictionary = _ray_floor_hit(nx, floor_y_feet, 2.0, 2.0)
		if h.is_empty():
			return x
		x = nx
	return x
