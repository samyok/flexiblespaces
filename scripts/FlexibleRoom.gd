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
var current_rotation = 0 
var last_room
var next_room
var last_door
var next_door
var doors
var door_proximity_zones
var room_entry_zones
var rooms_parent # Node to hide all rooms
var rooms # Wall pointers
var signs # Left sign pointers
var door_guides # Door guide pointers
var floor_guides # Floor guide pointers (0: turn left, 1: straight, 2: turn right)
var signs_shown = []
var last_controller
var current_section

var dfs = true # True for Depth-first search, False for Breadth-first search
var dfs_room_order =        [0, 1, 3, 1, 5, 4, 0, 2, 6]
var dfs_door_guide_order =  [0, 0, -1, 0, 2, 3, 2, 3, -1]
var dfs_floor_guide_order = [3, 2, -1, 0, 1, 2, 2, 1, -1]
var bfs_room_order = [0, 1, 2, 4, 5, 1, 3, 1, 0, 2, 6]
var bfs_door_guide_order = []
var bfs_floor_guide_order = []
var current_search_index = 0
 
# Room A has B north, E to the east, C to the south, and _ to the west
# Room B has D north, F to the east, _ to the south, and A to the west
# Room C has _ north, A to the east, _ to the south, and G to the west
# Room D has _ north, _ to the east, _ to the south, and B to the west
# Room E has _ north, _ to the east, F to the south, and A to the west
# Room F has _ north, E to the east, _ to the south, and B to the west
# Room G has _ north, C to the east, _ to the south, and _ to the west
var adjacencies = [[1, 4, 2, -2], [3, 5, -2, 0], [-2, 0, -2, 6], [-2, -2, -2, 1], [-2, -2, 5, 0], [-2, 4, -2, 1], [-2, 2, -2, -2]]
var explored = [true, false, false, false, false, false, false]

var tokens 
var active_token
var lerp_start_point
var overlay
var lerp_alpha
var lerp_time = 2

signal entered_hallway(start_door, end_door)
signal exited_hallway
signal explored_room(room)
signal hallway_transition(index)

func _ready():
	last_controller = %LeftController
	doors = self.find_children("Door*Area")
	door_proximity_zones = self.find_children("*DoorProximityZone")
	room_entry_zones = self.find_children("*RoomEntryVerificationZone")
	rooms_parent = self.find_child("Rooms")
	rooms = rooms_parent.find_children("Room?")
	signs = self.find_child("Signs").find_children("Sign?")
	door_guides = self.find_child("Guides").find_children("DoorGuide*")
	floor_guides = self.find_child("Guides").find_children("FloorGuide*")
	tokens = self.find_children("Token?")
	tokens.push_front(null)
	overlay = %Overlay
	if dfs:
		door_guides[dfs_door_guide_order[0]].show()
		floor_guides[dfs_floor_guide_order[0]].show()
	else:	
		door_guides[bfs_door_guide_order[0]].show()
		floor_guides[bfs_floor_guide_order[0]].show()

func _process(delta):
	if active_token != null:
		lerp_alpha += delta
		if lerp_alpha > lerp_time:
			active_token.hide()
			active_token = null
		else:
			active_token.global_position = lerp(lerp_start_point, %TokenStartPosition.global_position, lerp_alpha)
			active_token.global_rotation = Vector3(lerp(0.0, 8*PI, lerp_alpha), lerp(0.0, 2*PI, lerp_alpha), -lerp(0.0, 2*PI, lerp_alpha))
			active_token.scale = Vector3(lerp_time - lerp_alpha, lerp_time - lerp_alpha, lerp_time - lerp_alpha)
		

func start_token_animation(room):
	active_token = tokens[room]
	lerp_start_point = active_token.global_position
	lerp_alpha = 0

func swap_room():
	
	var door
	for i in 4:
		door = adjacencies[current_room][i]
		if door == -2:
			doors[i].hide()
		else:
			doors[i].show()
			if explored[door]:
				var sign = signs[door]
				# Rotate signs to be at current door
				sign.rotation.y = -PI*i/2
				# Show the signs
				sign.show()
				# Mark them to be hidden when next entering a hallway
				signs_shown.push_front(sign)
				
	rooms[current_room].show()
	if not explored[current_room]:
		explored[current_room] = true
		explored_room.emit(current_room)
		start_token_animation(current_room)

# Called when user moves from hallway -> threshhold
# Renders room without exploring it
func render_room(room, door):
	var current_search_index = self.current_search_index
	if door == last_door:
		current_search_index -= 1
	if adjacencies[room][door] != -2:
		if dfs:
			if room == dfs_room_order[current_search_index]:
				if dfs_door_guide_order[current_search_index] != -1:
					door_guides[dfs_door_guide_order[current_search_index]].show()
				if dfs_floor_guide_order[current_search_index] != -1:
					floor_guides[dfs_floor_guide_order[current_search_index]].show()
		else:
			if room == bfs_room_order[current_search_index]:
				if bfs_door_guide_order[current_search_index] != -1:
					door_guides[bfs_door_guide_order[current_search_index]].show()
				if bfs_floor_guide_order[current_search_index] != -1:
					floor_guides[bfs_floor_guide_order[current_search_index]].show()
	rooms[room].show()
	rooms_parent.show()

# Called when user moves from threshhold -> room
# Explores room and sets it as current room, and unrenders hallway
func exit_hallway(door):
	# Came back the same way
	if last_door == door:
		current_room = last_room
		swap_room()
		exited_hallway.emit()
	# Went to the other door
	elif next_door == door:
		current_room = next_room
		swap_room()
		exited_hallway.emit()
		if dfs:
			if current_room == dfs_room_order[current_search_index]:
				if dfs_door_guide_order[current_search_index] != -1:
					door_guides[dfs_door_guide_order[current_search_index]].show()
				if dfs_floor_guide_order[current_search_index] != -1:
					floor_guides[dfs_floor_guide_order[current_search_index]].rotation.y = -PI*door/2
					floor_guides[dfs_floor_guide_order[current_search_index]].show()
		else:
			if current_room == bfs_room_order[current_search_index]:
				if bfs_door_guide_order[current_search_index] != -1:
					door_guides[bfs_door_guide_order[current_search_index]].show()
				if bfs_floor_guide_order[current_search_index] != -1:
					floor_guides[bfs_floor_guide_order[current_search_index]].rotation.y = -PI*door/2
					floor_guides[bfs_floor_guide_order[current_search_index]].show()
		rooms_parent.show()

# Called when user moves from room -> threshhold
# Renders full hallway and enters it
func enter_hallway(door):
		last_room = current_room
		next_room = adjacencies[current_room][door]
		if dfs:
			if next_room == dfs_room_order[current_search_index+1]:
				current_search_index += 1
		else:
			if next_room == bfs_room_order[current_search_index+1]:
				current_search_index += 1
		last_door = door
		for i in 4:
			if adjacencies[next_room][i] == last_room:
				next_door = i
		entered_hallway.emit(last_door, next_door)
		current_room = -1

# Called when user moves from threshhold -> hallway proper
# Unrenders room
func unrender_room(room, door):
	for guide in door_guides:
		guide.hide()
	for guide in floor_guides:
		guide.hide()
	rooms[room].hide()
	rooms_parent.hide()
	var size = signs_shown.size()
	for i in size:
		var sign = signs_shown.pop_front()
		sign.hide()
	for i in 4:
		doors[i].hide()
	doors[last_door].show()
	doors[next_door].show()
	current_room = -1

func _on_door_entered(area):
	for i in 4:
		# Entered door
		if area == doors[i]:
			if current_room == -1:
				exit_hallway(i)
			else:
				enter_hallway(i)
				current_section = 0
		# Entered threshold
		elif area == door_proximity_zones[i]:
			# If in Middle
			if current_section == 1:
				if i == last_door:
					hallway_transition.emit(2) # MIDDLE BIT to DOOR1
					current_section = 0
				elif i == next_door:
					hallway_transition.emit(3) # MIDDLE BIT to DOOR2
					current_section = 2
			
			if i == last_door and current_section == 1:
				if not rooms[last_room].is_visible():
					render_room(last_room, i)
			elif i == next_door and current_section == 1:
				if not rooms[next_room].is_visible():
					render_room(next_room, i)


func _on_door_exited(area):
	for i in 4:
		if area == door_proximity_zones[i]:
			if current_room == -1:
				if i == last_door:
					unrender_room(last_room, i)
				elif i == next_door:
					unrender_room(next_room, i)
				if i == last_door:
					hallway_transition.emit(0) # DOOR1 to MIDDLE BIT
					current_section = 1
				if i == next_door:
					hallway_transition.emit(1) # DOOR2 to MIDDLE BIT
					current_section = 1
				print("Unrendering room at door: " + str(i))
	
func _on_map_right_controller_signal():
	last_controller = %RightController


func _on_map_left_controller_signal():
	last_controller = %LeftController
