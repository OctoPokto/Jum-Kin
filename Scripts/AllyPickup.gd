extends Area2D
class_name AllyPickup

@export var follower_scene: PackedScene
@export var delay_frames_base: int = 12
@export var delay_frames_step: int = 8

@export var info: FollowerInfo

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_node("MovementRecorder") or not body.has_method("add_follower"):
		return

	var follower = follower_scene.instantiate()
	follower.global_position = global_position
	var idx: int = 0
	if body.has_method("get_follower_count"):
		idx = int(body.call("get_follower_count"))

	if follower.has_method("set_line_index"):
		follower.set_line_index(idx)
	if follower.has_method("set_recorder"):
		var rec_node = body.get_node("MovementRecorder")
		follower.set_recorder(rec_node)

	# Stagger delay so they form a train
	if "delay_frames" in follower:
		follower.delay_frames = delay_frames_base + idx * delay_frames_step

	if info != null:
		if follower.has_method("set_info"):
			follower.set_info(info)
		elif "info" in follower:
			follower.info = info

	get_tree().current_scene.add_child(follower)
	body.call("add_follower", follower)
	queue_free()
	
	var dialogue := get_tree().current_scene.get_node("Control/Dialogue")
	if dialogue:
		dialogue.update_message(info.pickupDialogue, global_position, info.color)
