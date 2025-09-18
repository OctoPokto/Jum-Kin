extends Control
class_name LoadingScreen

# UI
@export var label_path: NodePath = ^"Label"   # point at your Label / RichTextLabel

# Dots animation
@export var dot_interval: float = 0.35        # seconds per dot change
@export var max_dots: int = 3                 # 0..max_dots cycles

# Timing
@export var min_show_sec: float = 0.75        # always show at least this long
@export var auto_load_after_sec: float = 1.5  # when to trigger the scene change

# Target scene (set one of these)
@export var next_scene: PackedScene
@export var next_scene_path: String           # e.g. "res://scenes/Level02.tscn"

var _label: Label
var _elapsed: float = 0.0
var _dot_elapsed: float = 0.0
var _dots: int = 0
var _loaded: bool = false

func set_next_scene(scene: PackedScene) -> void:
	next_scene = scene

func set_next_scene_path(path: String) -> void:
	next_scene_path = path

func _ready() -> void:
	# Make sure label exists
	_label = get_node_or_null(label_path)
	if _label == null:
		push_warning("LoadingScreen: label_path doesn't point to a Label.")
	_update_text()  # initial "Now Loading"

	# Optional: force black bg if your scene is just a Control
	# self_modulate = Color.BLACK    # if your root is a ColorRect instead, skip this

func _process(delta: float) -> void:
	_elapsed += delta
	_dot_elapsed += delta

	# animate dots
	if _dot_elapsed >= dot_interval:
		_dot_elapsed = 0.0
		_dots = (_dots + 1) % (max_dots + 1)
		_update_text()

	# load when time has passed (respecting minimum show time)
	if not _loaded and _elapsed >= max(min_show_sec, auto_load_after_sec):
		_loaded = true
		_load_next()

func _update_text() -> void:
	if _label == null:
		return
	var dots := ""
	for i in _dots:
		dots += "."
	_label.text = "Now Loading" + dots

func _load_next() -> void:
	if next_scene:
		get_tree().change_scene_to_packed(next_scene)
	elif next_scene_path != "":
		get_tree().change_scene_to_file(next_scene_path)
	else:
		push_warning("LoadingScreen: No next_scene or next_scene_path set.")
