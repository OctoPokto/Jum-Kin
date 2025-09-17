extends CharacterBody2D

@onready var line = $Line2D
@onready var animated_sprite_2d = $AnimatedSprite2D
var current_animation = "idle"

const SPEED = 150.0
const ACCELERATION = 300.0*10
const FRICTION = 300.0*20

const JUMP_VELOCITY = -300.0
var jump_force : Vector2
var angle
var jump_timer = 1
var jump_timer_max = 2
var jump_toggle : bool
var velocity_before_bounce = 0

var input_axis = Input.get_axis("ui_left", "ui_right")
var input_direction = Input.get_vector("A_left","D_right","W_up","S_down")

var prior_input : Array = [.0,.0,.0,.0] #left right up down
var time_passed : float = 0.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")*2

var height_reached

signal follower_count_changed(count: int)
@onready var recorder = $MovementRecorder
var followers := []

signal landed_up_screen
signal landed_down_screen
var _was_on_floor: bool = false
var _last_landed_screen: Vector2i = Vector2i.ZERO
@export var cam_node: NodePath
var _cam: Node = null

func _ready():
	landed_up_screen.connect(_on_test_up)
	landed_down_screen.connect(_on_test_down)
	_was_on_floor = is_on_floor()
	_cam = get_node_or_null(cam_node)
	if _cam and _cam.has_method("_getCurrentScreen"):
		var cs: Variant = _cam.call("_getCurrentScreen")
		var v: Vector2 = cs
		_last_landed_screen = Vector2i(int(round(v.x)), int(round(v.y)))

func _on_test_up() -> void:
	var scr := ""
	if _cam and _cam.has_method("_getCurrentScreen"):
		scr = str(_cam.call("_getCurrentScreen"))
	print("[TEST] landed_up_screen  screen=", scr)

func _on_test_down() -> void:
	var scr := ""
	if _cam and _cam.has_method("_getCurrentScreen"):
		scr = str(_cam.call("_getCurrentScreen"))
	print("[TEST] landed_down_screen  screen=", scr)


func add_follower(f) -> void:
	followers.append(f)
	emit_signal("follower_count_changed", followers.size())

func get_follower_count() -> int:
	return followers.size()

func _physics_process(delta): #Delta is the time between physics ticks. Currently set to 1/60
	time_passed += delta
	velocity.y += gravity * delta
	
	handle_animations()
	
	time_input_held()
	handle_prior_input(input_direction)
	update_input_direction()
	
	if is_on_floor():
		_handle_jump(input_direction, delta)
		_handle_acceleration(input_axis, delta)
		apply_friction(input_axis, delta)
		
		if velocity.x == 0 && input_direction != Vector2.ZERO: #When player is still and is using arrow keys.
			_handle_look_direction(input_direction)
			#print (input_direction)
	elif !is_on_floor():
		collide_on_wall()
	input_axis = Input.get_axis("ui_left", "ui_right")
	move_and_slide()
	
	var now_on_floor: bool = is_on_floor()
	if now_on_floor and not _was_on_floor:
		var cur: Vector2i = _last_landed_screen
		if _cam and _cam.has_method("_getCurrentScreen"):
			var cs2: Variant = _cam.call("_getCurrentScreen")
			var v2: Vector2 = cs2
			cur = Vector2i(int(round(v2.x)), int(round(v2.y)))

		var dy: int = cur.y - _last_landed_screen.y
		if dy < 0:
			emit_signal("landed_up_screen")      # success (went up)
		elif dy > 0:
			emit_signal("landed_down_screen")    # fall (went down)

		_last_landed_screen = cur
	_was_on_floor = now_on_floor
	
	if is_instance_valid(recorder):
		recorder.push_sample(
			global_position,
			animated_sprite_2d.flip_h,
			animated_sprite_2d.animation,
			animated_sprite_2d.get_frame()
		)
	

func _handle_jump(input_direction, delta):
	
	if Input.is_action_pressed("ui_select") and jump_timer<jump_timer_max:
		jump_toggle = true
		jump_timer += delta*1.5
		snapped(jump_timer,0.5)
		if jump_timer < 1:
			jump_timer = 1
		if(jump_timer>jump_timer_max):
			jump_timer = jump_timer_max
		
	if Input.is_action_just_released("ui_select"): 
		
		# If no side movement
		if input_direction.x == 0 :
			jump_force = Vector2(0,1)
		# else if sidemovement, but not full side movement
		elif abs(input_direction.x) > 0.1 and abs(input_direction.x) < 0.9:
			if input_direction.x < 0: 
				jump_force = Vector2(0.5,0.8)#left jump
			else:
				jump_force = Vector2(-0.5,0.8)#right jump
		#else long jump to the sides
		else:
			if input_direction.x < 0: #left long jump
				jump_force = Vector2(0.7,0.4)
			else:
				jump_force = Vector2(-0.7,0.4) #right long jump
		#if input_direction != 0:
			
		var debug = jump_force * (JUMP_VELOCITY*jump_timer)
		velocity = jump_force * (JUMP_VELOCITY*jump_timer)
		
		#print(debug)
		jump_timer = 1
		jump_toggle = false
	
func apply_friction(input_axis, delta):#decelerate movement
	if(input_axis == 0):
		velocity.x = move_toward(velocity.x, 0, FRICTION*delta)
		
func _handle_acceleration(input_axis, delta): #accelerate movement
	if input_axis != 0 and !Input.is_action_pressed("ui_select"):
		velocity.x = move_toward(velocity.x, SPEED*input_axis, ACCELERATION*delta)
	
func _handle_look_direction(input_direction):
	animated_sprite_2d.animation = "look"
	if input_direction.length() !=0:
		animated_sprite_2d.flip_h = false
		angle = input_direction.angle()/(PI/4)
		angle = wrapi(int(angle),0,8)
		animated_sprite_2d.set_frame(angle)

func collide_on_wall():
	if velocity.x !=0:
		velocity_before_bounce = velocity.x
		if velocity_before_bounce == null:
			velocity_before_bounce = 0
	if is_on_wall() and velocity.x == 0:
		velocity.x = (velocity_before_bounce*-1)*0.6
		
func handle_animations():
	if velocity.x < 0:
		animated_sprite_2d.flip_h = true
	elif velocity.x > 0:
		animated_sprite_2d.flip_h = false
	
	if velocity.x != 0 && is_on_floor(): #When player is moving left or right
		animated_sprite_2d.play("walk")
	elif jump_toggle:
		animated_sprite_2d.animation = "jump"
		animated_sprite_2d.set_frame(0) 
	elif !is_on_floor() && velocity.y < 0:
		animated_sprite_2d.animation = "jump"
		animated_sprite_2d.set_frame(1)
	elif !is_on_floor() && velocity.y > 0:
		animated_sprite_2d.animation = "jump"
		animated_sprite_2d.set_frame(2)
	else:
		animated_sprite_2d.play("idle")
	

func update_trajectory(dir:Vector2, speed:float, delta):
	var max_points = 64

	line.clear_points()
	var pos: Vector2 = Vector2.ZERO
	var vel = dir * speed
	for i in max_points:
		line.add_point(pos)
		vel.y += gravity * delta
		pos += vel * delta
		
func time_input_held(): 
	if Input.is_action_pressed("A_left"):
		prior_input[0] = time_passed
	if Input.is_action_pressed("D_right"):
		prior_input[1] = time_passed
	if Input.is_action_pressed("W_up"):
		prior_input[2] = time_passed
	if Input.is_action_pressed("S_down"):
		prior_input[3] = time_passed

func handle_prior_input(check_key):
	var delay :float = 0.3
	match check_key:
		"left":
			if (prior_input[0]+delay > time_passed) and prior_input[0] > prior_input[1]:
				return true
			else:
				return false
		"right":
			if (prior_input[1]+delay > time_passed) and prior_input[1] > prior_input[0]:
				return true
			else : return false
		"up":
			if (prior_input[2]+delay > time_passed) and prior_input[2] > prior_input[3]:
				return true
			else : return false
		"down":
			if (prior_input[3]+delay > time_passed) and prior_input[3] > prior_input[2]:
				return true
			else : return false

func update_input_direction():
	input_direction = Vector2.ZERO
	
	if handle_prior_input("left"):
		input_direction.x = -1
	if handle_prior_input("right"):
		input_direction.x = 1
	if handle_prior_input("up"):
		input_direction.y = -1
	if handle_prior_input("down"):
		input_direction.y = 1
	if input_direction.length() != 0:
		input_direction = input_direction.normalized()
	#print(input_direction, "input direction")
