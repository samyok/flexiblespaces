extends Node3D

class_name FlexibleRoom

# 0: North, 1: East, 2: South, 3:West
var current_room = 0
						#-2: wall
						#-1: hallway
						# 0: A
						# 1: B
						# 2: C
						# 3: D
						# 4: E
						# 5: F
						# 6: G
var last_room
var next_room
var last_door
var doors # Door pointers
var walls # Wall pointers
var textures # Texture pointers
var signs # TODO: use these

#           D--B--F
#              |  |  
#        G--C--A--E  
# Room A has B north, E to the east, _ to the south, and C to the west
# Room B has _ north, F to the east, A to the south, and D to the west
# Room C has _ north, A to the east, _ to the south, and G to the west
# Room D has _ north, B to the east, _ to the south, and _ to the west
# Room E has F north, _ to the east, _ to the south, and A to the west
# Room F has _ north, _ to the east, E to the south, and B to the west
# Room G has _ north, C to the east, _ to the south, and _ to the west
var adjacencies = [[1, 4, -2, 2], [-2, 5, 0, 3], [-2, 0, -2, 6], [-2, 1, -2, -2], [5, -2, -2, 0], [-2, -2, 4, 1], [-2, 2, -2, -2]]

signal entered_hallway(start_door, end_door) # TODO: link to hallway
signal exited_hallway # TODO: link to hallway

func _ready():
	doors = [self.find_child("DoorNorth"), self.find_child("DoorEast"), self.find_child("DoorSouth"), self.find_child("DoorWest")]
	walls = [self.find_child("WallNorth"), self.find_child("WallEast"), self.find_child("WallSouth"), self.find_child("WallWest")]
	textures = [] # TODO: instanciate

func _process(delta):
	pass

func change_context(door):
	# If currently in a room
	if current_room > -1:
		self.hide()
		last_room = current_room
		next_room = adjacencies[current_room][door]
		last_door = door
		entered_hallway.emit(last_room, next_room)
		current_room = -1
	# If in a hallway
	else:
		# Came back the same way
		if last_door == door:
			current_room = last_room
		# Went to the other door
		else:
			current_room = next_room
			swap_room()
		exited_hallway.emit()
		self.show()

func swap_room():
	var door
	var texture = textures[current_room]
	for i in 4:
		door = adjacencies[current_room][i]
		if door == -2:
			doors[i].hide()
		else:
			doors[i].show()
		walls[i].texture = texture # TODO: make this work

# TODO: Link to point hitbox on the camera
func _on_door_entered(name):
	if name == "DoorNorthArea":
		change_context(0)
	elif name == "DoorEastArea":
		change_context(1)
	elif name == "DoorSouthArea":
		change_context(2)
	elif name == "DoorWestArea":
		change_context(3)
