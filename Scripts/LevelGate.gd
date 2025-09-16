extends Area2D
class_name LevelGate

@export var next_scene: PackedScene
@export var auto_count_pickups: bool = true
@export var required_followers: int = 0
@export var pickup_group: StringName = &"ally_pickup"
@export var open_on_touch: bool = true
@export var show_label: bool = true
@export var player_group: StringName = &"player"  # optional: add your player to this group

@onready var blocker: CollisionShape2D = get_node_or_null("CollisionShape2D")
@onready var label: Label = get_node_or_null("Label")

var _armed: bool = true

func _ready() -> void:
	# Must have a shape to detect overlaps
	if !has_node("CollisionShape2D"):
		push_warning("[LevelGate] No CollisionShape2D child found.")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	if auto_count_pickups:
		required_followers = _count_pickups_once()
		print("[LevelGate] Required followers (auto): ", required_followers)
	else:
		print("[LevelGate] Required followers (manual): ", required_followers)

	_update_label()  # clear text

func _count_pickups_once() -> int:
	var total: int = 0
	for _n in get_tree().get_nodes_in_group(pickup_group):
		total += 1
	return total

func _on_body_entered(body: Node) -> void:
	if !_armed:
		return
	if body == null:
		return

	# Make sure it's the player (either by method or group)
	var looks_like_player: bool = body.has_method("get_follower_count") or body.is_in_group(player_group)
	if !looks_like_player:
		# Something else touched the gate
		return

	var have: int = 0
	if body.has_method("get_follower_count"):
		have = (body.call("get_follower_count") as int)
	elif "followers" in body and body.followers is Array:
		have = (body.followers as Array).size()
	else:
		# We don't know the count; keep the gate closed and tell you why.
		push_warning("[LevelGate] Body entered but no follower count available. Add get_follower_count() to the player.")
		return

	print("[LevelGate] Player touched gate. have=", have, " need=", required_followers)
	_update_label(have)

	if have < required_followers:
		# Not enough → stay closed
		return

	# Enough → unlock
	_armed = false
	if blocker:
		blocker.disabled = true

	if open_on_touch and next_scene:
		get_tree().change_scene_to_packed(next_scene)

func _on_body_exited(_body: Node) -> void:
	_update_label()

func _update_label(have: int = -1) -> void:
	if !show_label or label == null:
		return
	if have < 0:
		label.text = ""
		return
	var lack: int = max(0, required_followers - have)
	label.text = "" if lack <= 0 else "Need %d more" % lack
