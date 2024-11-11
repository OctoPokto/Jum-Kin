extends CharacterBody2D
@onready var animated_sprite_2d = $AnimatedSprite2D

const speed = 100.0

var jump_power = -1000*10
var jump_timer_max = 3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	move_and_collide(Vector2(0,gravity*delta)) #Gravity applied every frame
	#velocity.y += gravity*delta #something is funky here. m&c works fine, but this suddenly doesn't work
	floor_check(delta)
	#print(floor_check(delta))
	handle_movement(delta)
	handle_jump(delta)
	
func handle_jump(delta):
	#if Input.is_action_pressed("ui_accept"):
		##The longer button is held the more force is applied to the jump
		##If the player is currently colliding with ground then it can jump
		#null
	if Input.is_action_just_released("ui_accept"):
		#Apply force in direction
		#velocity.y += jump_power
		move_and_collide(Vector2(0, jump_power*delta))
		print("You jumped!")
		
func handle_movement(delta):
	velocity = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1 * speed
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1 * speed
		
	if velocity.length() >0:
		velocity = velocity.normalized() * speed
	
	move_and_collide(velocity * delta)
func floor_check(delta):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(Vector2(0,0), Vector2(0,0.1))
	query.exclude=[self]
	var result = space_state.intersect_ray(query)
	#var floor_check = move_and_collide(velocity*delta)
	if query:
		return true
	else:
		return false

func _on_input_event(viewport, event, shape_idx):
	pass
