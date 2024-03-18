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
var over = -1 # Signifies the panel currently being interacted with: -1: no panel, 0: map panel, 1: bank panel, 2: tutorial panel
var map_normal_guide
var bank_x_min_right = -7.5
var bank_x_max_right = 0
var bank_x_min_left = 0
var bank_x_max_left = 7.5
var bank_y_min = -3.75
var bank_y_max = 3.75
var left_bank
var left_bank_panel
var left_bank_normal_guide
var left_bank_cursor
var left_bank_laser
var left_bank_room_list
var left_bank_room_holder_list
var left_bank_room_holder_group
var bank_room_holder_group_offset_left = Vector3(-.08, -0.02, 0)
var right_bank
var right_bank_panel
var right_bank_normal_guide
var right_bank_cursor
var right_bank_laser
var right_bank_room_list
var right_bank_room_holder_list
var right_bank_room_holder_group
var bank_room_holder_group_offset_right = Vector3(.08, -0.02, 0)
var bank_held_rooms = [true, false, false, false, false, false, false]
var bank_room_to_cursor_proximity = 1.4
var mapping_sprite
var choosing_sprite
var controls_alert_sprite

signal pause_stick_movement
signal resume_stick_movement
signal left_controller_signal
signal right_controller_signal

# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	camera = %XRCamera3D
	overlay = %Overlay
	map_normal_guide = self.find_child("MapNormalGuide")
	path_multi_mesh = find_child("Paths").multimesh
	corner_multi_mesh = find_child("Corners").multimesh
	map_cursor = find_child("MapCursor")
	map_laser = find_child("MapLaser")
	room_list = {0: find_child("Room1"), 1: find_child("Room2"), 2: find_child("Room3"), 3: find_child("Room4"), 4: find_child("Room5"), 5: find_child("Room6"), 6: find_child("Room7")}
	room_ghost_map = {room_list.values()[0]: find_child("GhostRoom1"), room_list.values()[1]: find_child("GhostRoom2"), room_list.values()[2]: find_child("GhostRoom3"), room_list.values()[3]: find_child("GhostRoom4"), room_list.values()[4]: find_child("GhostRoom5"), room_list.values()[5]: find_child("GhostRoom6"), room_list.values()[6]: find_child("GhostRoom7")}
	left_bank = %LeftBank
	left_bank_panel = %LeftBank/Panel
	left_bank_normal_guide = %LeftBank/LeftBankNormalGuide
	left_bank_cursor = %LeftBank/BankCursor
	left_bank_laser =  %LeftBank/BankCursor/BankLaser
	left_bank_room_list = {0: find_child("LeftBankRoom1"), 1: find_child("LeftBankRoom2"), 2: find_child("LeftBankRoom3"), 3: find_child("LeftBankRoom4"), 4: find_child("LeftBankRoom5"), 5: find_child("LeftBankRoom6"), 6: find_child("LeftBankRoom7")}
	left_bank_room_holder_list = find_children("LeftRoomHolder?")
	left_bank_room_holder_group = find_child("LeftRoomHolderss")
	right_bank = %RightBank
	right_bank_panel = %RightBank/Panel
	right_bank_normal_guide = %RightBank/RightBankNormalGuide
	right_bank_cursor = %RightBank/BankCursor
	right_bank_laser =  %RightBank/BankCursor/BankLaser
	right_bank_room_list = {0: find_child("RightBankRoom1"), 1: find_child("RightBankRoom2"), 2: find_child("RightBankRoom3"), 3: find_child("RightBankRoom4"), 4: find_child("RightBankRoom5"), 5: find_child("RightBankRoom6"), 6: find_child("RightBankRoom7")}
	right_bank_room_holder_list = find_children("RightRoomHolder?")
	right_bank_room_holder_group = find_child("RightRoomHolderss")
	mapping_sprite = %Overlay/MappingSprite
	choosing_sprite = %Overlay/ChoosingSprite
	controls_alert_sprite = %Overlay/ControlsAlertSprite
	for i in [0, 1, 2, 3, 4, 5, 6]:
		left_bank_room_list.values()[i].global_position = left_bank_room_holder_list[i].global_position
		left_bank_room_list.values()[i].position += block_height_offset
		right_bank_room_list.values()[i].global_position = right_bank_room_holder_list[i].global_position
		right_bank_room_list.values()[i].position += block_height_offset

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
		var left_bank_plane = Plane((left_bank_normal_guide.global_position - left_bank.global_position).normalized(), left_bank.global_position)
		var right_bank_plane = Plane((right_bank_normal_guide.global_position - right_bank.global_position).normalized(), right_bank.global_position)
		
		if input_vector.length() > scaling_deadzone:
			self.scale = self.scale + Vector3(scaling_speed * input_vector.y, scaling_speed * input_vector.y, scaling_speed * input_vector.y)
			if self.scale.x < min_scale:
				self.scale = Vector3(min_scale, min_scale, min_scale)
			elif self.scale.x > max_scale:
				self.scale = Vector3(max_scale, max_scale, max_scale)
		
		var bank_x_min
		var bank_x_max
		var bank_plane
		
		# Right controller panel update
		if node_currently_interacting == right_controller: #left bank
			bank_plane = right_bank_plane
			#left_bank.position = (-1 * bank_offset) + bank_position
			#bank.rotation = -1 * bank_rotation
			#bank_panel.position = -1 * bank_panel_offset
			bank_x_min = bank_x_min_right
			bank_x_max = bank_x_max_right
			right_bank_room_holder_group.position = bank_room_holder_group_offset_right

		# Left controller panel update
		elif node_currently_interacting == left_controller: #right bank
			bank_plane = left_bank_plane
			#bank.position = bank_offset + bank_position
			#bank.rotation = bank_rotation
			#bank_panel.position = bank_panel_offset
			bank_x_min = bank_x_min_left
			bank_x_max = bank_x_max_left
			left_bank_room_holder_group.position = bank_room_holder_group_offset_left
		
		# If not in-bounds on any others, check for in-bounds on all of the panels
		if over == -1:
			map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
			#bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
			#if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
				#transition_to_map()
			#elif not (bank_cursor.position.x > bank_x_max or bank_cursor.position.x < bank_x_min or bank_cursor.position.y > bank_y_max or bank_cursor.position.y < bank_y_min):
				#transition_to_bank()
			if node_currently_interacting == left_controller: 
				right_bank_cursor.global_position = right_bank_plane.project(node_currently_interacting.global_position)
				if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
					transition_to_map()
				elif not (right_bank_cursor.position.x > bank_x_max or right_bank_cursor.position.x < bank_x_min or right_bank_cursor.position.y > bank_y_max or right_bank_cursor.position.y < bank_y_min):
					transition_to_bank()
			elif node_currently_interacting == right_controller: 
				left_bank_cursor.global_position = left_bank_plane.project(node_currently_interacting.global_position)
				if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
					transition_to_map()
				elif not (left_bank_cursor.position.x > bank_x_max or left_bank_cursor.position.x < bank_x_min or left_bank_cursor.position.y > bank_y_max or left_bank_cursor.position.y < bank_y_min):
					transition_to_bank()

		# Already tracking map panel
		elif over == 0:
			# Check if cursor is off of map
			map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
			if map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min:
				# If so: check if on bank
				#bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
				#if not (bank_cursor.position.x > bank_x_max or bank_cursor.position.x < bank_x_min or bank_cursor.position.y > bank_y_max or bank_cursor.position.y < bank_y_min):
					#transition_to_bank()
				#else:
					#slip_from_map()
				if node_currently_interacting == left_controller:
					right_bank_cursor.global_position = right_bank_plane.project(node_currently_interacting.global_position)
					if not (right_bank_cursor.position.x > bank_x_max or right_bank_cursor.position.x < bank_x_min or right_bank_cursor.position.y > bank_y_max or right_bank_cursor.position.y < bank_y_min):
						transition_to_bank()
					else:
						slip_from_map()
				elif node_currently_interacting == right_controller: 
					left_bank_cursor.global_position = left_bank_plane.project(node_currently_interacting.global_position)
					if not (left_bank_cursor.position.x > bank_x_max or left_bank_cursor.position.x < bank_x_min or left_bank_cursor.position.y > bank_y_max or left_bank_cursor.position.y < bank_y_min):
						transition_to_bank()
					else:
						slip_from_map()

		# Already tracking bank panel
		else:
			# Check if cursor is off of bank
			#bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
			#if bank_cursor.position.x > bank_x_max or bank_cursor.position.x < bank_x_min or bank_cursor.position.y > bank_y_max or bank_cursor.position.y < bank_y_min:
			# If so: check if on map
				#map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
				#if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
					#transition_to_map()
				#else:
					#slip_from_bank()
			if node_currently_interacting == left_controller:
				left_bank_cursor.global_position = left_bank_plane.project(node_currently_interacting.global_position)
				if left_bank_cursor.position.x > bank_x_max or left_bank_cursor.position.x < bank_x_min or left_bank_cursor.position.y > bank_y_max or left_bank_cursor.position.y < bank_y_min:
					map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
					if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
						transition_to_map()
					else:
						slip_from_bank()
			elif node_currently_interacting == right_controller:
				right_bank_cursor.global_position = right_bank_plane.project(node_currently_interacting.global_position)
				if right_bank_cursor.position.x > bank_x_max or right_bank_cursor.position.x < bank_x_min or right_bank_cursor.position.y > bank_y_max or right_bank_cursor.position.y < bank_y_min:
					map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
					if not (map_cursor.position.x > map_x_max or map_cursor.position.x < map_x_min or map_cursor.position.y > map_y_max or map_cursor.position.y < map_y_min):
						transition_to_map()
					else:
						slip_from_bank()

		# Interacting with the map panel
		if over == 0:
			
			map_cursor.global_position = map_plane.project(node_currently_interacting.global_position)
			map_laser.scale = Vector3(1, 1, map_cursor.global_position.distance_to(node_currently_interacting.global_position)/(self.scale.z*3))
			var laser_position_offset = map_cursor.global_position.distance_to(node_currently_interacting.global_position)/(-2*(self.scale.z*3))
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
				dragging_room.position = map_cursor.position + dragging_float_height
				#Dragging Ghost
				dragging_room_ghost.position = cursor_block + block_height_offset + grid_offset
				if valid_block():
					dragging_room_ghost.show()
				else:
					dragging_room_ghost.hide()
			
			# Pathing
			elif pathing:
				# New block in path
				if current_path_last_block != cursor_block:
					# If the block is valid and next to the path
					if (rooms.has(cursor_block) or valid_block()) and is_adjacent(current_path_last_block, cursor_block):
						# Corner revision case
						if current_path_second_to_last_block != null and (current_path_last_block - current_path_second_to_last_block) + current_path_last_block != cursor_block:
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
								if current_path_origin != cursor_block and rooms.has(cursor_block):
									pathing_clean_up() 
								else:
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
								if current_path_origin != cursor_block and rooms.has(cursor_block):
									pathing_clean_up() 
								else:
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
								if current_path_origin != cursor_block and rooms.has(cursor_block):
									pathing_clean_up() 
								else:
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
								if current_path_origin != cursor_block and rooms.has(cursor_block):
									pathing_clean_up() 
								else:
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
						# Path ending case
						elif current_path_origin != cursor_block and rooms.has(cursor_block):
							pathing_clean_up()
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
					# Backtracking case
					else:
						# Delete the last path
						pass
		# Interacting with bank panel
		elif over == 1:
			#bank_cursor.global_position = bank_plane.project(node_currently_interacting.global_position)
			#bank_laser.scale = Vector3(1, 1, bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/(self.scale.z * bank.scale.z))
			#var laser_position_offset = bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/(-2*self.scale.z * bank.scale.z)
			#if bank_plane.is_point_over(node_currently_interacting.global_position):
				#bank_laser.position = Vector3(0, 0, laser_position_offset)
			#else:
				#bank_laser.position = Vector3(0, 0, -laser_position_offset)
			#
			##Dragging
			#if dragging: 
				#dragging_room.position = bank_cursor.position + dragging_float_height
			
			if node_currently_interacting == left_controller: 
				left_bank_cursor.global_position = left_bank_plane.project(node_currently_interacting.global_position)
				left_bank_laser.scale = Vector3(1, 1, left_bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/((self.scale.z*3) * left_bank.scale.z))
				var laser_position_offset = left_bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/(-2*(self.scale.z*3) * left_bank.scale.z)
				if left_bank_plane.is_point_over(node_currently_interacting.global_position):
					left_bank_laser.position = Vector3(0, 0, laser_position_offset)
				else:
					left_bank_laser.position = Vector3(0, 0, -laser_position_offset)
					
				if dragging: 
					dragging_room.position = left_bank_cursor.position + dragging_float_height
			
			elif node_currently_interacting == right_controller: 
				right_bank_cursor.global_position = right_bank_plane.project(node_currently_interacting.global_position)
				right_bank_laser.scale = Vector3(1, 1, right_bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/((self.scale.z*3) * right_bank.scale.z))
				var laser_position_offset = right_bank_cursor.global_position.distance_to(node_currently_interacting.global_position)/(-2*(self.scale.z*3) * right_bank.scale.z)
				if right_bank_plane.is_point_over(node_currently_interacting.global_position):
					right_bank_laser.position = Vector3(0, 0, laser_position_offset)
				else:
					right_bank_laser.position = Vector3(0, 0, -laser_position_offset)
					
				if dragging: 
					dragging_room.position = right_bank_cursor.position + dragging_float_height
		# Interacting with no panels
		else:
			pass

func is_adjacent(vec3_1, vec3_2):
	for x in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT]:
		if vec3_1 + x == vec3_2:
			return true
	return false

func transition_to_map():
	mapping_sprite.show()
	choosing_sprite.hide()
	controls_alert_sprite.show()
	map_cursor.show()
	right_bank_cursor.hide()
	left_bank_cursor.hide()
	over = 0
	if dragging:
		dragging_room.hide()
		var i
		if node_currently_interacting == left_controller: 
			i = left_bank_room_list.find_key(dragging_room)
			right_bank_room_list.values()[i].hide()
		elif node_currently_interacting == right_controller: 
			i = right_bank_room_list.find_key(dragging_room)
			left_bank_room_list.values()[i].hide()
		if (i==4):
			pass
		print(str("Transition to map - dragging: ", i))
		dragging_room = room_list.values()[i]
		dragging_room.show()
		dragging_room_ghost = room_ghost_map[dragging_room]
		dragging_room_ghost.show()

func transition_to_bank():
	mapping_sprite.hide()
	choosing_sprite.show()
	controls_alert_sprite.show()
	map_cursor.hide()
	#bank_cursor.show()
	over = 1
	if node_currently_interacting == left_controller:
		left_bank_cursor.show()
		if dragging:
			dragging_room.hide()
			var i = room_list.find_key(dragging_room)
			print(str("Transition to bank - dragging: ", i))
			dragging_room = left_bank_room_list.values()[i]
			dragging_room.show()
			right_bank_room_list.values()[i].show()
			dragging_room_ghost.hide()
			dragging_room_ghost = null
			recalibrate_holders()
		elif pathing:
			pathing_clean_up()
	elif node_currently_interacting == right_controller: 
		right_bank_cursor.show()
		if dragging:
			dragging_room.hide()
			var i = room_list.find_key(dragging_room)
			print(str("Transition to bank - dragging: ", i))
			dragging_room = right_bank_room_list.values()[i]
			dragging_room.show()
			left_bank_room_list.values()[i].show()
			dragging_room_ghost.hide()
			dragging_room_ghost = null
			recalibrate_holders()
		elif pathing:
			pathing_clean_up()
	
func slip_from_map():
	mapping_sprite.hide()
	controls_alert_sprite.hide()
	map_cursor.hide()
	if dragging:
		dragging_cancel()
	elif pathing:
		pathing_clean_up()
	over = -1
	
func slip_from_bank():
	choosing_sprite.hide()
	controls_alert_sprite.hide()
	left_bank_cursor.hide()
	right_bank_cursor.hide()
	if dragging:
		dragging_cancel()
	over = -1
	
func put_back_room(room, left):
	room.show()
	if left:
		var i = left_bank_room_list.find_key(room)
		bank_held_rooms[i] = true
		room.global_position = left_bank_room_holder_list[i].global_position
		room.position += block_height_offset
	else:
		var i = right_bank_room_list.find_key(room)
		bank_held_rooms[i] = true
		room.global_position = right_bank_room_holder_list[i].global_position
		room.position += block_height_offset

func recalibrate_holders():
	if node_currently_interacting == left_controller:
		for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]):
			left_bank_room_list.values()[x].global_position = left_bank_room_holder_list[x].global_position
	elif node_currently_interacting == right_controller:
		for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]):
			right_bank_room_list.values()[x].global_position = right_bank_room_holder_list[x].global_position

# Returns true or false based on if this block is available for drawing
func valid_block():
	return !(paths.has(cursor_block) or corners.has(cursor_block) or rooms.has(cursor_block) or cursor_block == null)

# Attempts to start pathing at the current block
func start_path():
	pathing = true
	# Initialize path variables
	current_path_last_block = cursor_block
	current_path_origin = cursor_block
	if rooms.has(cursor_block):
		current_path_second_to_last_block = null
		current_path_start_room = rooms.get(cursor_block)

# Cleans up pathing
func pathing_clean_up():
	double_click_timing = false
	pathing = false
	var valid_path = rooms.has(cursor_block)
	var end_room = cursor_block
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
			path_starts.remove_at(i)
			path_ends.remove_at(i)
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

# Attempts to start dragging the current block
func start_drag():
	# Interacting with room
	if over == 0:
		dragging = true
		dragging_room = rooms.get(cursor_block)
		rooms.erase(cursor_block)
		dragging_room_ghost = room_ghost_map[dragging_room]
		var i = path_accums.size()-1
		while i != -1:
			if path_starts[i] == dragging_room or path_ends[i] == cursor_block:
				delete_selection(path_accums[i].keys().front())
			i -= 1
	# Interacting with bank
	else:
		# For each held room
		#for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]).map(func(i):  return bank_room_list.values()[i]):
			#if bank_cursor.position.distance_to(x.position) < bank_room_to_cursor_proximity:
				#dragging = true
				#dragging_room = x
				#bank_held_rooms[bank_room_list.find_key(x)] = false
		if node_currently_interacting == left_controller:
			for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]).map(func(i):  return left_bank_room_list.values()[i]):
				if left_bank_cursor.position.distance_to(x.position) < bank_room_to_cursor_proximity:
					dragging = true
					dragging_room = x
					bank_held_rooms[left_bank_room_list.find_key(x)] = false
		elif node_currently_interacting == right_controller:
			for x in [0, 1, 2, 3, 4, 5, 6].filter(func(i): return bank_held_rooms[i]).map(func(i):  return right_bank_room_list.values()[i]):
				if right_bank_cursor.position.distance_to(x.position) < bank_room_to_cursor_proximity:
					dragging = true
					dragging_room = x
					bank_held_rooms[right_bank_room_list.find_key(x)] = false

# Cleans up room dragging
func dragging_clean_up():
	if over == 0:
		if valid_block:
			dragging_room.position = dragging_room_ghost.position
			rooms[cursor_block] = dragging_room
		else:
			dragging_room.hide()
			if node_currently_interacting == left_controller:
				put_back_room(left_bank_room_list.values()[room_list.find_key(dragging_room)], true)
			elif node_currently_interacting == right_controller:
				put_back_room(right_bank_room_list.values()[room_list.find_key(dragging_room)], false)
		dragging_room = null
		dragging_room_ghost.hide()
		dragging_room_ghost = null
		dragging = false
	else:
		if node_currently_tracking == left_controller:
			var i = left_bank_room_list.find_key(dragging_room)
			put_back_room(dragging_room, true)
			put_back_room(right_bank_room_list.values()[i], false)
		else:
			var i = right_bank_room_list.find_key(dragging_room)
			put_back_room(dragging_room, false)
			put_back_room(left_bank_room_list.values()[i], true)
		dragging_room = null
		dragging = false
		if dragging_room_ghost != null:
			dragging_room_ghost.hide()
		dragging_room_ghost = null

# Cleans up room dragging
func dragging_cancel():
	if over == 0:
		dragging_room.hide()
		var i = room_list.find_key(dragging_room)
		put_back_room(left_bank_room_list.values()[i], true)
		put_back_room(right_bank_room_list.values()[i], false)
		dragging_room = null
		dragging_room_ghost.hide()
		dragging_room_ghost = null
		dragging = false
	else:
		if node_currently_interacting == left_controller:
			var i = left_bank_room_list.find_key(dragging_room)
			put_back_room(dragging_room, true)
			put_back_room(right_bank_room_list.values()[i], false)
		else:
			var i = right_bank_room_list.find_key(dragging_room)
			put_back_room(dragging_room, false)
			put_back_room(left_bank_room_list.values()[i], true)
		dragging_room = null
		dragging = false
		if dragging_room_ghost != null:
			dragging_room_ghost.hide()
		dragging_room_ghost = null

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
		if node_currently_tracking == right_controller:
			left_bank.hide()
		node_currently_tracking = left_controller
		left_controller_signal.emit()
		node_currently_interacting = right_controller
		right_bank.show()
		pause_stick_movement.emit()
	elif name == "trigger_click" and node_currently_interacting == left_controller:
		if over == 0:
			if double_click_timing and double_click_start_block == cursor_block and (paths.has(cursor_block) or corners.has(cursor_block)):
				delete_selection(cursor_block)
			else:
				double_click_timer = 0.0
				double_click_timing = true
				double_click_start_block = cursor_block
				# start drag
				if rooms.has(cursor_block) and !dragging and !pathing:
					start_drag()
				
		elif over == 1:
			if (not dragging):
				start_drag()
	elif (name == "ax_button" or  name == "by_button") and node_currently_interacting == left_controller and over == 0 and rooms.has(cursor_block) and !dragging and !pathing:
		# start path
		start_path()

func _on_right_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != right_controller:
		if node_currently_tracking == left_controller:
			right_bank.hide()
		self.show()
		node_currently_tracking = right_controller
		right_controller_signal.emit()
		node_currently_interacting = left_controller
		left_bank.show()
		pause_stick_movement.emit()
	elif name == "trigger_click" and node_currently_interacting == right_controller:
		# Interacting with Map
		if over == 0:
			if double_click_timing and double_click_start_block == cursor_block and (paths.has(cursor_block) or corners.has(cursor_block)):
				delete_selection(cursor_block)
			else:
				double_click_timer = 0.0
				double_click_timing = true
				double_click_start_block = cursor_block
				# start drag
				if rooms.has(cursor_block) and !dragging and !pathing:
					start_drag()
				# start path
				elif temp_path_ghost != null and !rooms_queued:
					start_path()
		elif over == 1:
			if (not dragging):
				start_drag()
	elif (name == "ax_button" or  name == "by_button") and node_currently_interacting == right_controller and over == 0 and rooms.has(cursor_block) and !dragging and !pathing:
		# start path
		start_path()

func _on_left_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == left_controller:
		right_bank.hide()
		cancel_everything()
	elif name == "trigger_click":
		if over == 0:
			if node_currently_interacting == left_controller:
				if dragging:
					dragging_clean_up()
				elif pathing:
					pathing_clean_up()
		else:
			if dragging:
				dragging_cancel()
	elif (name == "ax_button" or name == "by_button") and over == 0 and pathing and node_currently_interacting == left_controller:
		pathing_clean_up()

func _on_right_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == right_controller:
		left_bank.hide()
		cancel_everything()
		
	elif name == "trigger_click":
		if over == 0:
			if node_currently_interacting == right_controller:
				if dragging:
					dragging_clean_up()
				elif pathing:
					pathing_clean_up()
		else:
			if dragging:
				dragging_cancel()
	elif (name == "ax_button" or name == "by_button") and over == 0 and pathing and node_currently_interacting == right_controller:
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
	put_back_room(right_bank_room_list.values()[room], false)
	put_back_room(left_bank_room_list.values()[room], true)
