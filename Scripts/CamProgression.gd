extends RemoteTransform2D
@onready var player = $"../Player"
@onready var camera_2d = $"../Camera2D" #Not really needed

var playerPos
var currentScreen : Vector2


func _ready():
	playerPos = player.position
	print("PlayerPos:","x:",playerPos.x,"y:",playerPos.y)
	print("CamPos:","x:",position.x,"y:",position.y)

func _process(delta):
	playerPos = player.position
	if position.y-240 > playerPos.y: #going up
		position.y -= 480
		currentScreen.y -= 1
		#print("PlayerPos:","x:",playerPos.x,"y:",playerPos.y)
		#print("CamPos:","x:",position.x,"y:",position.y)
		print("Screen: ","x: ",currentScreen.x,"y: ", currentScreen.y)
		
	if position.y+240 < playerPos.y: #going down
		position.y += 480
		currentScreen.y += 1
		#print("PlayerPos:","x:",playerPos.x,"y:",playerPos.y)
		#print("CamPos:","x:",position.x,"y:",position.y)
		print("Screen: ","x: ",currentScreen.x,"y: ", currentScreen.y)

		
	if position.x-320 > playerPos.x: #going left
		position.x -=640
		currentScreen.x -= 1
		#print("PlayerPos:","x:",playerPos.x,"y:",playerPos.y)
		#print("CamPos:","x:",position.x,"y:",position.y)
		print("Screen: ","x: ",currentScreen.x,"y: ", currentScreen.y)

	if position.x+320 < playerPos.x: #going right
		position.x +=640
		currentScreen.x += 1
		#print("PlayerPos:","x:",playerPos.x,"y:",playerPos.y)
		#print("CamPos:","x:",position.x,"y:",position.y)
		print("Screen: ","x: ",currentScreen.x,"y: ", currentScreen.y)
		
func _getCurrentScreen():
	return currentScreen
