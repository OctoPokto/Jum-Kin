extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
var current_animation = "idle"

const SPEED = 150.0
const ACCELERATION = 300.0*10
const FRICTION = 300.0*20

const JUMP_VELOCITY = -500.0
const JUMP_VELOCITY_HORIZONTAL = -500.0
var jump_max = -2000.0
var angle
var jump_timer = 0.5
var jump_timer_max = 2
var jump_toggle : bool

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")*1.5


func _physics_process(delta): #Delta is the time between physics ticks. Currently set to 1/60
	velocity.y += gravity * delta

	if is_on_floor():
		var input_axis = Input.get_axis("ui_left", "ui_right")
		var input_direction = Input.get_vector("arrow_left","arrow_right","arrow_up","arrow_down")
		
		_handle_jump(input_direction, delta)
		_handle_acceleration(input_axis, delta)
		apply_friction(input_axis, delta)

		if velocity.x != 0: #When player is moving left or right
			animated_sprite_2d.play("walk")
		elif !velocity && input_direction: #When player is still and is using arrow keys.
			_handle_look_direction(input_direction)
		else:
			animated_sprite_2d.play("idle")
	if not is_on_floor():
		animated_sprite_2d.play("idle") #Replace this with jumping anim
		collide_on_wall()
	
	#My attempt at fixing collisions
	#var collision_info = move_and_collide(velocity*delta)
	#if velocity == Vector2.ZERO:
		#var collision: KinematicCollision2D = move_and_collide(velocity * delta)
		#if collision:
			#velocity = velocity.bounce(collision.get_normal())
		
		#if collision_info:
			#velocity = velocity.bounce(collision_info.get_normal())
		#print("wall velocity:",velocity.x)
	
	move_and_slide()

func _handle_jump(input_direction, delta):
	
	if Input.is_action_pressed("ui_select") and jump_timer<jump_timer_max:
		jump_toggle = true
		jump_timer += delta*3
		#print(jump_timer)
		if(jump_timer>jump_timer_max):
			jump_timer = jump_timer_max
		
	if Input.is_action_just_released("ui_select"):
		#velocity = Vector2(-input_direction.x*JUMP_VELOCITY_HORIZONTAL,JUMP_VELOCITY*jump_timer)
		velocity.y += JUMP_VELOCITY
		print("You jumped!")
		jump_timer = 0.5
		jump_toggle = false
	
func apply_friction(input_axis, delta):#decelerate movement
	if(input_axis == 0):
		velocity.x = move_toward(velocity.x, 0, FRICTION*delta)
		
func _handle_acceleration(input_axis, delta): #accelerate movement
	if input_axis != 0 and !Input.is_action_pressed("ui_select"):
		velocity.x = move_toward(velocity.x, SPEED*input_axis, ACCELERATION*delta)
		if velocity.x < 0:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
	#I'm thinking I might want to replace the whole walking part with pikuniku like inverse kinematics
	
func _handle_look_direction(input_direction):
	animated_sprite_2d.flip_h = false
	animated_sprite_2d.animation = "look"
	if input_direction.length() !=0:
		angle = input_direction.angle()/(PI/4)
		angle = wrapi(int(angle),0,8)
		animated_sprite_2d.set_frame(angle)
		
func collide_on_wall():
	var v
	if velocity.x !=0:
		v = velocity.x
	if is_on_wall() and velocity.x == 0:
		velocity.x = (v*-1)*0.6
