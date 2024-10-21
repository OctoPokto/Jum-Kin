extends RemoteTransform2D
@onready var player = $"../Player"
@onready var camera_2d = $"../Camera2D" #Not really needed

var playerPos

func _ready():
	playerPos = player.position
	print("CamPos:",position.y)
	print("PlayerPos:",playerPos.y)

func _process(delta):
	playerPos = player.position
	if position.y-240 > playerPos.y: #going up
		position.y -= 480
		print("PlayerPos:",playerPos.y)
		print("CamPos:",position.y)
		
	if position.y+240 < playerPos.y: #going down
		position.y += 480
		print("PlayerPos:",playerPos.y)
		print("CamPos:",position.y)
	
