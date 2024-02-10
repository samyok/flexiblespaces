extends Node3D

var node_currently_tracking = null # updates the position and rotation of the Map to this node's transform in _process
var node_currently_interacting = null 
var camera
var left_controller
var right_controller
var rotation_min = 0
var rotation_max = PI/2
var input_vector = Vector2(0.0, 0.0)
var scaling_deadzone = .2
var scaling_speed = 0.005
var min_scale = .01
var max_scale = .1
var map_cursor
var cursor_block
var map_x_max = 5
var map_x_min = -5
var map_y_min = 0
var map_y_max = 10
var path_multi_mesh
var corner_multi_mesh
var rooms = {} # Room array (Vector2 -> Room node dictionary)
var paths = {} # Path array (Vector2 -> instance id)
var corners = {} # Path corner array (Vector2 -> instance id)
var dragging_room # null or the room being currently dragged
var dragging_room_ghost # null or the ghost of the room being currently dragged
var dragging_float_height = Vector3(0, 0, -1.5)
var current_path_origin
var current_path_last_block
var current_path_second_to_last_block
var double_click_timer = 0
var double_click_timing = false
var double_click_start_block
var double_click_window = .4 # Maximum time (in seconds) between first and second click when double clicking
var room_queue = []
var rooms_queued = false
var block_height_offset = Vector3(0, 0, -0.5)
var left_top_rotation = 0.0 # default
var top_right_rotation = PI/2 # left 90 degrees
var right_bottom_rotation = PI # 180 degree rotation
var bottom_left_rotation = -PI/2 # right 90 degrees 
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
var overlay
var map_laser
var bank
var bank_position = Vector3(0, 3.75, 0)
var bank_offset = Vector3(5, 0, 0)
var bank_rotation = Vector3(0, PI/6, 0)
var bank_panel
var bank_panel_offset = Vector3(3.75, 0, 0)
var over = -1 # Signifies the panel currently being interacted with: -1: no panel, 0: map panel, 1: bank panel, 2: tutorial panel
var map_normal_guide
var bank_normal_guide
var bank_x_min_right = -7.5
var bank_x_max_right = 0
var bank_x_min_left = 0
var bank_x_max_left = 7.5
var bank_y_min = -3.75
var bank_y_max = 3.75
var bank_cursor
var bank_laser
var bank_room_list
var bank_room_holder_list
var bank_held_rooms = [true, false, false, false, false, false, false]
var bank_room_to_cursor_proximity = 1.4
var bank_room_holder_group
var bank_room_holder_group_offset_left = Vector3(2.558, -0.02, 0)
var bank_room_holder_group_offset_right = Vector3(-2.558, -0.02, 0)

signal pause_stick_movement
signal resume_stick_movement

# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	camera = %XRCamera3D
	overlay = %Overlay
	bank = %RoomBank
	bank_panel = %RoomBank/Panel
	map_normal_guide = self.find_child("MapNormalGuide")
	bank_normal_guide = %RoomBank/BankNormalGuide
	path_multi_mesh = find_child("Paths").multimesh
	corner_multi_mesh = find_child("Corners").multimesh
	map_cursor = find_child("MapCursor")
	bank_cursor = %RoomBank/BankCursor
	map_laser = find_child("MapLaser")
	bank_laser =  %RoomBank/BankCursor/BankLaser
	room_list = [find_child("Room1"), find_child("Room2"), find_child("Room3"), find_child("Room4"), find_child("Room5"), find_child("Room6"), find_child("Room7")]
	room_ghost_map = {room_list[0]: find_child("GhostRoom1"), room_list[1]: find_child("GhostRoom2"), room_list[2]: find_child("GhostRoom3"), room_list[3]: find_child("GhostRoom4"), room_list[4]: find_child("GhostRoom5"), room_list[5]: find_child("GhostRoom6"), room_list[6]: find_child("GhostRoom7")} 
	bank_room_list = find_children("BankRoom?")
	bank_room_holder_list = find_children("RoomHolder?")
	bank_room_holder_group = find_child("RoomHolderss")
	for i in [0, 1, 2, 3, 4, 5, 6]:
		bank_room_list[i].global_position = bank_room_holder_list[i].global_position
		bank_room_list[i].position += block_height_offset
		print(bank_room_list[i].position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if node_currently_tracking != null:
		self.global_position = node_currently_tracking.global_position
		var adjusted_camera_position = camera.global_position
		adjusted_camera_position.y = self.global_position.y
		self.look_at(adjusted_camera_position)
		var rotation_x = -node_currently_tracking.rotation.x + PI/4
		if rotation_x < rotation_min:
			rotation_x = rotation_min
		elif rotation_x > rotation_max:
			rotation_x = rotation_max
		self.rotation.x = rotation_x
		overlay.rotation.x = 0 - rotation_x
		var map_plane = Plane((map_normal_guide.global_position - self.global_position).normalized(), self.global_position)
		var bank_plane = Plane((bank_normal_guide.global_position - bank.global_position).normalized(), bank.global_position)
		
		if input_vector.length() > scaling_deadzone:
			self.scale = self.scale + Vector3(scaling_speed * input_vector.y, scaling_speed * input_vector.y, scaling_speed * input_vector.y)
			if self.scale.x < min_scale:
				self.scale = Vector3(min_scale, min_scale, min_scale)
			elif self.scale.x > max_scale:
				self.scale = Vector3(max_scale, max_scale, max_scale)
		
		var bank_x_min
		var bank_x_max
		# Right controller panel update
		if node_currently_interacting == right_controller:
			bank.position = (-1 * bank_offset) + bank_position
			bank.rotation = -1 * bank_rotation
			bank_panel.position = -1 * bank_panel_offset
			bank_x_min = bank_x_min_right
			bank_x_max = bank_x_max_right
			bank_room_holder_group.position = bank_room_holder_group_offset_right

		# Left controller panel update
		else:
			bank.position = bank_offset + bank_position
			bank.rotation = bank_rotation
			bank_panel.position = bank_panel_offset
			bank_x_min = bank_x_min_left
			bank_x_max = bank_x_max_left
			bank_room_holder_group.position = bank_room_holder_group_offset_left
		
		# If not in-bounds on any others, check for in-bounds on all of the panels
		if over == -1:
			map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
			bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
			if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
				transition_to_map()
			elif not (bank_cursor.position.x > bank_x_max or bank_cursor.position.x < bank_x_min or bank_cursor.position.y > bank_y_max or bank_cursor.position.y < bank_y_min):
				transition_to_bank()
				
		# Already tracking map panel
		elif over == 0:
			# Check if cursor is off of map
			map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
			if map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min:
				# If so: check if on bank
				bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
				if not (bank_cursor.position.x > bank_x_max or bank_cursor.position.x < bank_x_min or bank_cursor.position.y > bank_y_max or bank_cursor.position.y < bank_y_min):
					transition_to_bank()
				else:
					slip_from_map()
					
		# Already tracking bank panel
		else:
			# Check if cursor is off of bank
			bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
			if bank_cursor.position.x > bank_x_max or bank_cursor.position.x < bank_x_min or bank_cursor.position.y > bank_y_max or bank_cursor.position.y < bank_y_min:
				# If so: check if on map
				map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
				if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
					transition_to_map()
				else:
					slip_from_bank()
		
		# Interacting with the map panel
		if over == 0:
			
			map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
			map_laser.scale = Vector3(1, 1, map_cursor.global_position.distance_to(node_currently_interacting.global_position)/self.scale.z)
			var laser_position_offset = map_cursor.global_position.distance_to(node_currently_interacting.global_position)/(-2*self.scale.z)
			if map_plane.is_point_over(node_currently_interacting.global_position):
				map_laser.position = Vector3(0, 0, laser_position_offset)
			else:
				map_laser.position = Vector3(0, 0, -laser_position_offset)

					
			# Map Cursor block identification
			cursor_block = map_cursor.position.ceil()
			cursor_block.z = 0
			
			# Double click timing
			if double_click_timing:
				double_click_timer += delta
				if double_click_timer > double_click_window:
					double_click_timing = false
			
			# Dragging
			if dragging:
				delete_path_ghost()
				dragging_room.position = map_cursor.position + dragging_float_height
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
							# Left and Top
							if (current_path_second_to_last_block - current_path_last_block == Vector3(-1, 0, 0) or cursor_block - current_path_last_block == Vector3(-1, 0, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector3(0, 1, 0) or cursor_block - current_path_last_block == Vector3(0, 1, 0)):
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
		# Interacting with bank panel
		elif over == 1:
			bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
			bank_laser.scale = Vector3(1, 1, bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/(self.scale.z * bank.scale.z))
			var laser_position_offset = bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/(-2*self.scale.z * bank.scale.z)
			if bank_plane.is_point_over(node_currently_interacting.global_position):
				bank_laser.position = Vector3(0, 0, laser_position_offset)
			else:
				bank_laser.position = Vector3(0, 0, -laser_position_offset)
			
			#Dragging
			if dragging: 
				dragging_room.position = bank_cursor.position + dragging_float_height

		# Interacting with no panels
		else:
			pass

func is_adjacent(vec3_1, vec3_2):
	for x in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
		if vec3_1 + x == vec3_2:
			return true
	return false

func transition_to_map():
	map_cursor.show()
	bank_cursor.hide()
	over = 0
	if dragging:
		dragging_room.hide()
		var i = bank_room_list.bsearch(dragging_room)
		dragging_room = room_list[i]
		dragging_room.show()
		dragging_room_ghost = room_ghost_map[dragging_room]

func transition_to_bank():
	map_cursor.hide()
	bank_cursor.show()
	over = 1
	if dragging:
		dragging_room.hide()
		dragging_room = bank_room_list[room_list.bsearch(dragging_room)]
		dragging_room.show()
	elif pathing:
		pathing_clean_up()
	
func slip_from_map():
	map_cursor.hide()
	over = -1
	if dragging:
		dragging_cancel()
	elif pathing:
		pathing_clean_up()
	
func slip_from_bank():
	bank_cursor.hide()
	over = -1
	if dragging:
		dragging_cancel()
	
func put_back_room(room):
	room.show()
	room.global_position = bank_room_holder_list[bank_room_list.bsearch(room)].global_position

func recalibrate_holders():
	for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]):
		bank_room_list[x].global_position = bank_room_holder_list[x].global_position

# Returns true or false based on if this block is available for drawing
func valid_block():
	return !(paths.has(cursor_block) or corners.has(cursor_block) or rooms.has(cursor_block) or cursor_block == null)

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
		# Path handling
		if p == 0:
			# Delete ghost path
			path_multi_mesh.set_instance_transform(i, Transform3D().scaled(delete_mesh_scale))
			if valid_path:
				# Spawn opaque path in its place
				i = path_instance_count
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
	# Interacting with room
	if over == 0:
		dragging = true
		dragging_room = rooms.get(cursor_block)
		rooms.erase(cursor_block)
		dragging_room_ghost = room_ghost_map[dragging_room]
		for i in path_accums.size():
			if path_starts[i] == dragging_room or path_ends[i] == dragging_room:
				delete_selection(path_accums[i].keys().front())
	# Interacting with bank
	else:
		# For each held room
		for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]).map(func(i):  return bank_room_list[i]):
			if bank_cursor.position.distance_to(x.position) < bank_room_to_cursor_proximity:
				dragging = true
				dragging_room = x
				bank_held_rooms[bank_room_list.bsearch(x)] = false

# Cleans up room dragging
func dragging_clean_up():
	if over == 0:
		if valid_block:
			dragging_room.position = dragging_room_ghost.position
			rooms[cursor_block] = dragging_room
		else:
			dragging_room.hide()
			put_back_room(bank_room_list[room_list.bsearch(dragging_room)])
		dragging_room = null
		dragging_room_ghost.hide()
		dragging_room_ghost = null
		dragging = false
	else:
		put_back_room(dragging_room)
		dragging_room = null

# Cleans up room dragging
func dragging_cancel():
	if over == 0:
		dragging_room.hide()
		put_back_room(bank_room_list[room_list.bsearch(dragging_room)])
		dragging_room = null
		dragging_room_ghost.hide()
		dragging_room_ghost = null
		dragging = false
	else:
		put_back_room(dragging_room)
		dragging_room = null

# Cleans up drawing pane and hides it, hiding all elements and terminating all pathing, dragging, or ghosts
func cancel_everything():
	self.hide()
	resume_stick_movement.emit()
	node_currently_tracking = null
	node_currently_interacting = null
	if dragging:
		dragging_clean_up()
	elif pathing:
		pathing_clean_up()
	
func _on_left_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != left_controller:
		self.show()
		node_currently_tracking = left_controller
		node_currently_interacting = right_controller
		node_
		pause_stick_movement.emit()
	elif name == "trigger_click":
		if node_currently_interacting == left_controller:
			if over == 0:
				if double_click_timing and double_click_start_block == cursor_block and (paths.has(cursor_block) or corners.has(cursor_block)):
					delete_selection(cursor_block)
				else:
					double_click_timer = 0.0
					double_click_timing = true
					double_click_start_block = cursor_block
					# start drag
					if rooms.has(cursor_block) and !dragging and !pathing and !rooms_queued:
						start_drag()
					# start path
					elif temp_path_ghost != null and !rooms_queued:
						start_path()
						
			elif over == 1:
				if (not dragging):
					start_drag()

func _on_right_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != right_controller:
		self.show()
		node_currently_tracking = right_controller
		node_currently_interacting = left_controller
		pause_stick_movement.emit()
	elif name == "trigger_click":
		if node_currently_interacting == right_controller:
			# Interacting with Map
			if over == 0:
				if double_click_timing and double_click_start_block == cursor_block and (paths.has(cursor_block) or corners.has(cursor_block)):
					delete_selection(cursor_block)
				else:
					double_click_timer = 0.0
					double_click_timing = true
					double_click_start_block = cursor_block
					# start drag
					if rooms.has(cursor_block) and !dragging and !pathing and !rooms_queued:
						start_drag()
					# start path
					elif temp_path_ghost != null and !rooms_queued:
						start_path()
			elif over == 1:
				if (not dragging):
					start_drag()


func _on_left_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == left_controller:
		cancel_everything()
	elif name == "trigger_click":
		if node_currently_interacting == right_controller:
			if dragging:
				dragging_clean_up()
			elif pathing:
				pathing_clean_up()
	elif name == "ax_button":
		print(cursor_block)
		

func _on_right_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == right_controller:
		cancel_everything()
	elif name == "trigger_click":
		if node_currently_interacting == right_controller:
			if dragging:
				dragging_clean_up()
			elif pathing:
				pathing_clean_up()
		

func _on_left_controller_input_vector_2_changed(name, value):
	if name == "primary":
		if node_currently_tracking == left_controller and value.length() > scaling_deadzone:
			input_vector = value
		else:
			input_vector = Vector2(0, 0)

func _on_right_controller_input_vector_2_changed(name, value):
	if name == "primary":
		if node_currently_tracking == right_controller and value.length() > scaling_deadzone:
			input_vector = value
		else:
			input_vector = Vector2(0, 0)

func _on_room_explored(room):
	bank_held_rooms[room] = true
	put_back_room(bank_room_list[room])
