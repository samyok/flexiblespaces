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
var next_door
var doors # Door pointers
var rooms # Wall pointers
var signs # TODO: use these
 
# Room A has B north, E to the east, C to the south, and _ to the west
# Room B has D north, F to the east, _ to the south, and A to the west
# Room C has _ north, A to the east, _ to the south, and G to the west
# Room D has _ north, _ to the east, _ to the south, and B to the west
# Room E has _ north, _ to the east, F to the south, and A to the west
# Room F has _ north, E to the east, _ to the south, and B to the west
# Room G has _ north, C to the east, _ to the south, and _ to the west
var adjacencies = [[1, 4, 2, -2], [3, 5, -2, 0], [-2, 0, -2, 6], [-2, -2, -2, 1], [-2, -2, 5, 0], [-2, 4, -2, 1], [-2, 2, -2, -2]]
var explored = [true, false, false, false, false, false, false]

signal entered_hallway(start_door, end_door)
signal exited_hallway
signal explored_room(room)

func _ready():
	doors = [%DoorNorthArea, %DoorEastArea, %DoorSouthArea, %DoorWestArea]
	rooms = [self.find_child("Room1"), self.find_child("Room2"), self.find_child("Room3"), self.find_child("Room4"), self.find_child("Room5"), self.find_child("Room6"), self.find_child("Room7")]
	

func _process(delta):
	pass

func shuffle_array(array):
	for i in array.size():
		for j in array.size():
			if i != j:
				var k = array[i]
				array[i] = array[j]
				array[j] = k

func change_context(door):
	# If currently in a room
	if current_room > -1:
		rooms[current_room].hide()
		self.hide()
		last_room = current_room
		next_room = adjacencies[current_room][door]
		last_door = door
		for i in 4:
			doors[i].hide()
		for i in 4:
			if adjacencies[next_room][i] == last_room:
				next_door = i
		doors[last_door].show()
		doors[next_door].show()
		entered_hallway.emit(last_room, next_room)
		current_room = -1
	# If in a hallway
	else:
		# Came back the same way
		if last_door == door:
			current_room = last_room
		# Went to the other door
		elif next_door == door:
			current_room = next_room
			swap_room()
			exited_hallway.emit()
			self.show()

func swap_room():
	
	var door
	for i in 4:
		door = adjacencies[current_room][i]
		if door == -2:
			doors[i].hide()
		else:
			doors[i].show()
	rooms[current_room].show()
	if not explored[current_room]:
		explored[current_room] = true
		explored_room.emit(current_room)

func _on_door_entered(area):
	for i in 4:
		if area == doors[i]:
			change_context(i)
