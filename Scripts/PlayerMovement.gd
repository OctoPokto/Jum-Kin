extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D

const speed = 100.0

var jump_power = -3
var jump_timer_max = 3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")/2


func _physics_process(delta):
	move_and_collide(Vector2(0,gravity*delta)) #Gravity applied every frame
	floor_check(delta)
	print(floor_check(delta))
	handle_movement(delta)
	handle_jump(delta)
	

func handle_jump(delta):
	#if Input.is_action_pressed("ui_accept"):
		##The longer button is held the more force is applied to the jump
		##If the player is currently colliding with ground then it can jump
		#null
	if Input.is_action_just_released("ui_accept"):
		#Apply force in direction
		#velocity.y = jump_power * delta
		move_and_collide(Vector2(0, jump_power*delta))
		print("You jumped!")
func handle_movement(delta):
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
		
	if velocity.length() >0:
		velocity = velocity.normalized() * speed
	
	move_and_collide(velocity * delta)
func floor_check(delta):
	var floor_check = move_and_collide(velocity*delta)
	if floor_check:
		return true
	else:
		return false


func _on_input_event(viewport, event, shape_idx):
	pass
