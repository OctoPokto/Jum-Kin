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

var prior_input : Array[Vector2]
var input_dictionary : Dictionary
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")*2

var height_reached

func _physics_process(delta): #Delta is the time between physics ticks. Currently set to 1/60
	velocity.y += gravity * delta
	handle_animations()
	
	if is_on_floor():
		_handle_jump(input_direction, delta)
		_handle_acceleration(input_axis, delta)
		apply_friction(input_axis, delta)
		hold_input()
		if velocity.x == 0 && input_direction != Vector2.ZERO: #When player is still and is using arrow keys.
			_handle_look_direction(input_direction)
			#print (input_direction)
	elif !is_on_floor():
		collide_on_wall()
	input_axis = Input.get_axis("ui_left", "ui_right")

	move_and_slide()
	

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
		
func hold_input(): #I have little clue where i'm going with this
	# The idea is to filter the input and spit out the input witht he most amount in the array or dictionary. Unsure what to use.
	if !prior_input: #This is to fill the array, but I'm testing dictionaries so it has no function right now
		prior_input.resize(5)
		prior_input.fill(Vector2.ZERO)
		print("Input array primed")
	var input_direction_raw = Input.get_vector("A_left","D_right","W_up","S_down")
	var ocurrence :int
	for i in range(input_dictionary.size()):# yeah, the content of this loop doesn't make sense
		if input_dictionary.keys()[i].key == input_direction_raw:
			input_dictionary.keys()[i].value +=1
		else:
			input_dictionary = {input_direction_raw : ocurrence}

	
