extends Node3D

var node_currently_tracking = null # updates the position and rotation of the Map to this node's transform in _process
var camera
var left_controller
var right_controller
var input_vector = Vector2(0.0, 0.0)
var scaling_deadzone = .2
var scaling_speed = 0.005
var min_scale = .01
var max_scale = .1
var cursor
var cursor_block
var path_multi_mesh
var corner_multi_mesh
var rooms = {} # Room array (Vector2 -> Room node dictionary)
var paths = {} # Path array (Vector2 -> instance id)
var corners = {} # Path corner array (Vector2 -> instance id)
var dragging_room # null or the room being currently dragged
var dragging_room_ghost # null or the ghost of the room being currently dragged
var dragging_float_height = Vector3(0, 0, -1.0)
var current_path_origin
var current_path_last_block
var current_path_second_to_last_block
var double_click_timer = 0
var double_click_timing = false
var double_click_start_block
var double_click_window = .4 # Maximum time (in seconds) between first and second click when double clicking
var room_queue = []
var rooms_queued = false
var room_index = 0
var block_height_offset = Vector3(0, 0, -0.5)
var left_top_rotation = 0.0 # default # TODO: tune these rotation offsets
var top_right_rotation = PI/2 # right 90 degrees
var right_bottom_rotation = PI # 180 degree rotation
var bottom_left_rotation = -PI/2 # left 90 degrees 
var vertical_rotation = 0 # default
var horizontal_rotation = PI/2
var delete_mesh_scale = Vector3.ZERO
var ghost_mesh_color = Color(1, 1, 1, .4)
var grid_offset = Vector3(-0.5, -0.5, 0.0)
var current_path = {} # Dictionary of Vector3 -> Vector3 (value x is key into mesh, y is 0 for paths and 1 for corners, z is the rotation of the path/corner: 0 for vertical, 1 for horizontal and 0 for left&top, 1 for top&right, 2 for right&bottom, and 3 for bottom&left)
var current_path_start_room # Null or the Room that the current path started from
var temp_path_ghost # block location of currently rendered path ghost (null if not rendering path ghost)
var temp_path_ghost_i
var temp_path_ghost_r
var path_accums = [] # List of Dictionaries of Paths (Path dictionaries are Vector3 -> Vector2)
var path_starts = [] # List of Room nodes that start the paths in path_accums
var path_ends = [] # List of Room nodes that end the paths in path_accums
var room_list
var room_ghost_map # Dictionary of Room -> Room
var dragging = false
var pathing = false
var rooms_total = 7 # Change when adding rooms
var paths_z_fighting_offset = Vector3(0, 0, -.01)
var corners_z_fighting_offset = Vector3(0, 0, -0.02)
var path_instance_count = 0
var corner_instance_count = 0
var laser
var test1
var test2
var test3
var test35
var test4
var test45

signal pause_stick_movement # TODO: link to locomotion.gd
signal resume_stick_movement # TODO: link to locomotion.gd

# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	camera = %XRCamera3D
	path_multi_mesh = find_child("Paths").multimesh
	corner_multi_mesh = find_child("Corners").multimesh
	cursor = find_child("Cursor") # TODO: instanciate
	laser = find_child("Laser")
	room_list = [find_child("Room1")]#, find_child(""), find_child(""), find_child(""), find_child(""), find_child(""), find_child(""), find_child(""), find_child("")] # TODO: instanciate
	room_ghost_map = {room_list[0]: find_child("GhostRoom1")}#, } # TODO: instanciate

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if node_currently_tracking != null:
		self.global_position = node_currently_tracking.global_position
		self.look_at(camera.global_position)
		if input_vector.length() > scaling_deadzone:
			self.scale = self.scale + Vector3(scaling_speed * input_vector.y, scaling_speed * input_vector.y, scaling_speed * input_vector.y)
			if self.scale.x < min_scale:
				self.scale = Vector3(min_scale, min_scale, min_scale)
			elif self.scale.x > max_scale:
				self.scale = Vector3(max_scale, max_scale, max_scale)

		# Right controller cursor update
		if node_currently_tracking == left_controller:
			var map_plane = Plane((left_controller.global_position - camera.global_position).normalized(), left_controller.global_position)
			cursor.global_position = map_plane.project(right_controller.global_position)
			laser.scale = Vector3(1, 1, cursor.global_position.distance_to(right_controller.global_position)/self.scale.z)
			laser.position = Vector3(0, 0, cursor.global_position.distance_to(right_controller.global_position)/(-2*self.scale.z))
			cursor_block = cursor.position.ceil()
			cursor_block.z = 0

		# Left controller cursor update
		else:
			var map_plane = Plane((right_controller.global_position - camera.global_position).normalized(), right_controller.global_position)
			cursor.global_position = map_plane.project(left_controller.global_position)
			laser.scale = Vector3(1, 1, cursor.global_position.distance_to(left_controller.global_position)/self.scale.z)
			laser.position = Vector3(0, 0, cursor.global_position.distance_to(left_controller.global_position)/(-2*self.scale.z))
			cursor_block = cursor.position.ceil()
			cursor_block.z = 0

		# Double click timing
		if double_click_timing:
			double_click_timer += delta
			if double_click_timer > double_click_window:
				double_click_timing = false
		
		# Dragging
		if dragging:
			delete_path_ghost()
			dragging_room.position = cursor.position + dragging_float_height
			#Dragging Ghost
			dragging_room_ghost.position = cursor_block + block_height_offset + grid_offset
			if valid_block():
				dragging_room_ghost.show()
			else:
				dragging_room_ghost.hide()
		
		# Pathing
		elif pathing:
			delete_path_ghost()
			if current_path_last_block != cursor_block:
				if valid_block() and is_adjacent(current_path_last_block, cursor_block):
					# Corner revision case
					if (current_path_last_block - current_path_second_to_last_block) + current_path_last_block != cursor_block:
						print("revising a corner")
						print(str("second2last: ", current_path_second_to_last_block))
						print(str("last: ", current_path_last_block))
						print(str("current: ", cursor_block))
						# Left and Top
						if (current_path_second_to_last_block - current_path_last_block == Vector3(-1, 0, 0) or cursor_block - current_path_last_block == Vector3(-1, 0, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector3(0, 1, 0) or cursor_block - current_path_last_block == Vector3(0, 1, 0)):
							print("left and top")
							# Hide current_path_last_block
							path_multi_mesh.set_instance_transform(paths.get(current_path_last_block), Transform3D().scaled(delete_mesh_scale))
							paths.erase(current_path_last_block)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corner_instance_count
							corners[current_path_last_block] = i
							corner_instance_count += 1
							corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, left_top_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector3(i, 1, 0)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var j = path_instance_count
								paths[cursor_block] = j 
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 0)
							else:
								var j = path_instance_count
								paths[cursor_block] = j 
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 1)
						# Top and Right
						if (current_path_second_to_last_block - current_path_last_block == Vector3(0, 1, 0) or cursor_block - current_path_last_block == Vector3(0, 1, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector3(1, 0, 0) or cursor_block - current_path_last_block == Vector3(1, 0, 0)):
							print("top and right")
							# Hide current_path_last_block
							path_multi_mesh.set_instance_transform(paths.get(current_path_last_block), Transform3D().scaled(delete_mesh_scale))
							paths.erase(current_path_last_block)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corner_instance_count
							corners[current_path_last_block] = i
							corner_instance_count += 1
							corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, top_right_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector3(i, 1, 1)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var j = path_instance_count
								paths[cursor_block] = j
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 0)
							else:
								var j = path_instance_count
								paths[cursor_block] = j
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 1)
						# Right and Bottom
						if (current_path_second_to_last_block - current_path_last_block == Vector3(1, 0, 0) or cursor_block - current_path_last_block == Vector3(1, 0, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector3(0, -1, 0) or cursor_block - current_path_last_block == Vector3(0, -1, 0)):
							print("right and bottom")
							# Hide current_path_last_block
							path_multi_mesh.set_instance_transform(paths.get(current_path_last_block), Transform3D().scaled(delete_mesh_scale))
							paths.erase(current_path_last_block)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corner_instance_count
							corners[current_path_last_block] = i
							corner_instance_count += 1
							corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, right_bottom_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector3(i, 1, 2)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var j = path_instance_count
								paths[cursor_block] = j 
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 0)
							else:
								var j = path_instance_count
								paths[cursor_block] = j
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 1)
						# Bottom and Left
						if (current_path_second_to_last_block - current_path_last_block == Vector3(0, -1, 0) or cursor_block - current_path_last_block == Vector3(0, -1, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector3(-1, 0, 0) or cursor_block - current_path_last_block == Vector3(-1, 0, 0)):
							print("bottom and left")
							# Hide current_path_last_block
							path_multi_mesh.set_instance_transform(paths.get(current_path_last_block), Transform3D().scaled(delete_mesh_scale))
							paths.erase(current_path_last_block)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corner_instance_count
							corners[current_path_last_block] = i
							corner_instance_count += 1
							corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, bottom_left_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector3(i, 1, 3)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var j = path_instance_count
								paths[cursor_block] = j
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 0)
							else:
								var j = path_instance_count
								paths[cursor_block] = j
								path_instance_count += 1
								path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(j, ghost_mesh_color)
								current_path[cursor_block] = Vector3(j, 0, 1)
					# Normal path creation case
					else:
						if (cursor_block - current_path_last_block).x == 0:
							var j = path_instance_count
							paths[cursor_block] = j 
							path_instance_count += 1
							path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
							path_multi_mesh.set_instance_color(j, ghost_mesh_color)
							current_path[cursor_block] = Vector3(j, 0, 0)
						else:
							var j = path_instance_count
							paths[cursor_block] = j 
							path_instance_count += 1
							path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
							path_multi_mesh.set_instance_color(j, ghost_mesh_color)
							current_path[cursor_block] = Vector3(j, 0, 1)
					current_path_second_to_last_block = current_path_last_block
					current_path_last_block = cursor_block
		# Room queued ghost
		elif rooms_queued and valid_block():
			delete_path_ghost()
			room_ghost_map[room_queue.front()].show()
			room_ghost_map[room_queue.front()].position = cursor_block + block_height_offset + grid_offset
		
		# Pathing ghost
		else:
			var skip = false
			if cursor_block != temp_path_ghost:
				delete_path_ghost()
			else:
				skip = true
			if not valid_block():
				skip = true
			if not skip:
				var adjacencies = [cursor_block + Vector3.UP, cursor_block + Vector3.DOWN, cursor_block + Vector3.LEFT, cursor_block + Vector3.RIGHT]
				var i = 0
				var spotted = false
				for x in adjacencies:
					if rooms.has(x):
						spotted = true
						if i < 2:
							var j = path_instance_count
							temp_path_ghost_i = j
							temp_path_ghost = cursor_block
							temp_path_ghost_r = 0
							path_instance_count += 1
							path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
							path_multi_mesh.set_instance_color(j, ghost_mesh_color)
						else:
							var j = path_instance_count
							temp_path_ghost_i = j
							temp_path_ghost = cursor_block
							temp_path_ghost_r = 1
							path_instance_count += 1
							path_multi_mesh.set_instance_transform(j, Transform3D().translated_local(paths_z_fighting_offset + cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
							path_multi_mesh.set_instance_color(j, ghost_mesh_color)
					i += 1

func is_adjacent(vec3_1, vec3_2):
	for x in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
		if vec3_1 + x == vec3_2:
			return true
	return false

# Returns true or false based on if this block is available for drawing
func valid_block():
	return !(paths.has(cursor_block) or corners.has(cursor_block) or rooms.has(cursor_block) or cursor_block == null)

# Attempts to place a room in the location from the queue
func place_room():
	print(str("placing: ", cursor_block))
	room_queue.front().position = cursor_block + block_height_offset + grid_offset
	room_queue.front().show()
	room_ghost_map[room_queue.front()].hide()
	rooms[cursor_block] = room_queue.pop_front()
	if room_queue.is_empty():
		rooms_queued = false
		

# Attempts to start pathing at the current block
func start_path():
	pathing = true
	# Initialize path variables
	current_path_last_block = cursor_block
	current_path_origin = cursor_block
	for x in [cursor_block + Vector3.UP, cursor_block + Vector3.DOWN, cursor_block + Vector3.LEFT, cursor_block + Vector3.RIGHT]:
		if rooms.has(x):
			current_path_second_to_last_block = x
			current_path_start_room = rooms.get(x)
	# Co-opt ghost path into current path
	temp_path_ghost = null
	paths[cursor_block] = temp_path_ghost_i
	current_path[cursor_block] = Vector3(temp_path_ghost_i, 0, temp_path_ghost_r)

# Cleans up pathing
func pathing_clean_up():
	double_click_timing = false
	pathing = false
	var valid_path = false
	var end_room
	if current_path.get(cursor_block) != null and current_path.get(cursor_block).z == 0:
		if rooms.has(cursor_block + Vector3.UP):
			valid_path = true
			end_room = rooms.get(cursor_block + Vector3.UP)
		elif rooms.has(cursor_block + Vector3.DOWN):
			valid_path = true
			end_room = rooms.get(cursor_block + Vector3.DOWN)
	elif current_path.get(cursor_block) != null:
		if rooms.has(cursor_block + Vector3.LEFT):
			valid_path = true
			end_room = rooms.get(cursor_block + Vector3.LEFT)
		elif rooms.has(cursor_block + Vector3.RIGHT):
			valid_path = true
			end_room = rooms.get(cursor_block + Vector3.RIGHT)
	# Replicate dictionary with new multimesh indices of non-ghosted paths and corners
	var path_accum = {}
	for k in current_path.keys():
		var v = current_path.get(k)
		var i = v.x
		var p = v.y
		var r = v.z
		print("deleting path at: ", i)
		# Path handling
		if p == 0:
			# Delete ghost path
			path_multi_mesh.set_instance_transform(i, Transform3D().scaled(delete_mesh_scale))
			if valid_path:
				# Spawn opaque path in its place
				i = path_instance_count
				print("spawning path with i: ", i)
				path_instance_count += 1
				# Vertical path creation
				if r == 0:
					path_multi_mesh.set_instance_transform(i, Transform3D().translated_local(paths_z_fighting_offset + k + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
				# Horizontal path creation
				else:
					path_multi_mesh.set_instance_transform(i, Transform3D().translated_local(paths_z_fighting_offset + k + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
				paths[k] = i
			else:
				paths.erase(k)
		# Corner replication
		else:
			# Delete ghost corner
			corner_multi_mesh.set_instance_transform(i, Transform3D().scaled(delete_mesh_scale))
			if valid_path:
				# Spawn opaque corner in its place
				i = corner_instance_count
				print("spawning corner with i: ", i)
				corner_instance_count += 1
				# Left Top corner creation
				if r == 0:
					corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + k + grid_offset).rotated_local(Vector3.FORWARD, left_top_rotation))
				# Top Right corner creation
				elif r == 1:
					corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + k + grid_offset).rotated_local(Vector3.FORWARD, top_right_rotation))
				# Right Bottom corner creation
				elif r == 2:
					corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + k + grid_offset).rotated_local(Vector3.FORWARD, right_bottom_rotation))
				# Bottom Left corner creation
				else:
					corner_multi_mesh.set_instance_transform(i, Transform3D().translated_local(corners_z_fighting_offset + k + grid_offset).rotated_local(Vector3.FORWARD, bottom_left_rotation))
				corners[k] = i
			else:
				corners.erase(k)
		if valid_path:
			path_accum[k] = Vector2(i, p)
			
			print("recording path component with i: ", i)
	if valid_path:
		path_accums.push_front(path_accum)
		path_starts.push_front(current_path_start_room)
		path_ends.push_front(end_room)
	current_path = {}
	current_path_start_room = null

# Deletes a completed path
func delete_selection(target):
	# Loop through all path dictionaries
	var i = 0
	for d in path_accums:
		# Find the path dictionary that has the currently hovered block
		if d.has(target):
			path_starts.erase(path_starts[i])
			path_ends.erase(path_ends[i])
			# Loop through its entries
			for k in d.keys():
				var v = d.get(k)
				# Path deletion
				if v.y == 0:
					paths.erase(k)
					path_multi_mesh.set_instance_transform(v.x, Transform3D().scaled(delete_mesh_scale))
				# Corner deletion
				else:
					corners.erase(k)
					corner_multi_mesh.set_instance_transform(v.x, Transform3D().scaled(delete_mesh_scale))
			# Erase it from the list of paths that exist
			path_accums.erase(d)
		i += 1
	

# Unrenders path ghost if it is being rendered
func delete_path_ghost():
	if temp_path_ghost != null:
		path_multi_mesh.set_instance_transform(temp_path_ghost_i, Transform3D().scaled(delete_mesh_scale))
		temp_path_ghost = null

# Attempts to start dragging the current block
func start_drag():
	dragging = true
	dragging_room = rooms.get(cursor_block)
	rooms.erase(cursor_block)
	dragging_room_ghost = room_ghost_map[dragging_room]
	for i in path_accums.size():
		if path_starts[i] == dragging_room or path_ends[1] == dragging_room:
			delete_selection(path_accums[i].keys().front())

# Cleans up room dragging
func dragging_clean_up():
	if valid_block:
		dragging_room.position = dragging_room_ghost.position
		rooms[cursor_block] = dragging_room
	else:
		dragging_room.hide()
		room_queue.push_front(dragging_room)
	dragging_room = null
	dragging_room_ghost.hide()
	dragging_room_ghost = null
	dragging = false

# Cleans up drawing pane and hides it, hiding all elements and terminating all pathing, dragging, or ghosts
func cancel_everything():
	self.hide()
	resume_stick_movement.emit()
	node_currently_tracking = null
	if dragging:
		dragging_clean_up()
	elif pathing:
		pathing_clean_up()
	else:
		delete_path_ghost()
	
func _on_left_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != left_controller:
		self.show()
		node_currently_tracking = left_controller
		pause_stick_movement.emit()
	elif name == "trigger_click":
		if node_currently_tracking == right_controller:
			if double_click_timing and double_click_start_block == cursor_block and (paths.has(cursor_block) or corners.has(cursor_block) ):
				delete_selection(cursor_block)
			else:
				double_click_timer = 0.0
				double_click_timing = true
				double_click_start_block = cursor_block
				# place room
				if valid_block and rooms_queued and !dragging and !pathing:
					place_room()
				# start drag
				elif rooms.has(cursor_block) and !dragging and !pathing and !rooms_queued:
					start_drag()
				# start path
				elif temp_path_ghost != null and !rooms_queued:
					start_path()
	elif name == "ax_button" or name == "by_button":
		on_room_explored(null)

func _on_right_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != right_controller:
		self.show()
		node_currently_tracking = right_controller
		pause_stick_movement.emit()
	elif name == "trigger_click":
		if node_currently_tracking == left_controller:
			if double_click_timing and double_click_start_block == cursor_block and (paths.has(cursor_block) or corners.has(cursor_block)):
				print("double_clicked")
				delete_selection(cursor_block)
			else:
				double_click_timer = 0.0
				double_click_timing = true
				double_click_start_block = cursor_block
				# place room
				if valid_block and rooms_queued and !dragging and !pathing:
					place_room()
				# start drag
				elif rooms.has(cursor_block) and !dragging and !pathing and !rooms_queued:
					start_drag()
				# start path
				elif temp_path_ghost != null and !rooms_queued:
					start_path()
	elif name == "ax_button" or name == "by_button":
		on_room_explored(null)


func _on_left_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == left_controller:
		cancel_everything()
	elif name == "trigger_click":
		if node_currently_tracking == right_controller:
			if dragging:
				dragging_clean_up()
			elif pathing:
				pathing_clean_up()
		

func _on_right_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == right_controller:
		cancel_everything()
	elif name == "trigger_click":
		if node_currently_tracking == left_controller:
			if dragging:
				dragging_clean_up()
			elif pathing:
				pathing_clean_up()
		

# TODO: attach signal from left controller
func _on_left_controller_input_vector_2_changed(name, value):
	if name == "primary":
		if node_currently_tracking == left_controller and value.length() > scaling_deadzone:
			input_vector = value
		else:
			input_vector = Vector2(0, 0)

# TODO: attach signal from right controller
func _on_right_controller_input_vector_2_changed(name, value):
	if name == "primary":
		if node_currently_tracking == right_controller and value.length() > scaling_deadzone:
			input_vector = value
		else:
			input_vector = Vector2(0, 0)

# TODO: attach signal from somewhere
func on_room_explored(Room):
	if room_index != rooms_total:
		rooms_queued = true
		room_queue.push_back(room_list[room_index])
		room_index += 1
