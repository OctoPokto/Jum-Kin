extends Node
class_name MovementRecorder

@export var max_samples: int = 1800

var positions := PackedVector2Array()
var flips := []
var anims := []
var frames := []

func push_sample(pos: Vector2, flip_h: bool, anim, frame: int) -> void:
	positions.append(pos)
	flips.append(flip_h)
	anims.append(anim)
	frames.append(frame)
	if positions.size() > max_samples:
		positions.remove_at(0)
		flips.remove_at(0)
		anims.remove_at(0)
		frames.remove_at(0)

func get_snapshot(delay_frames: int) -> Dictionary:
	var idx := positions.size() - 1 - delay_frames
	if idx < 0:
		return {}
	return {
		"pos": positions[idx],
		"flip_h": flips[idx],
		"anim": anims[idx],
		"frame": frames[idx],
	}
