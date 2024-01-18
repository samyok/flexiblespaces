extends Node3D

var node_currently_tracking = null # updates the position and rotation of the Map to this node's transform in _process
var camera
var left_controller
var right_controller
var grip_pressed = false
var last_cursor_position = Vector2(0.0, 0.0)
var input_vector = Vector2(0.0, 0.0)
var scaling_deadzone = .2
var scaling_speed = 0.2
var max_scale = 1.0
var cursor
var cursor_block
var active
var path_multi_mesh
var corner_multi_mesh
var rooms = {} # Room array (Vector2 -> Room node dictionary)
var paths = {} # Path array (Vector2 -> instance id)
var corners = {} # Path corner array (Vector2 -> instance id)
var adjacencies # Vector3 array (path index, room id1, room id 2)
var dragging_room # null or the room being currently dragged
var dragging_room_ghost # null or the ghost of the room being currently dragged
var dragging_path # null or the path being currently dragged
var dragging_float_height = 1.0
var valid_path_start
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
var drawing_plane
var block_height_offset = .5 # TODO: calibrate with starting scale
var left_top_rotation = 0.0 # default # TODO: tune these rotation offsets
var top_right_rotation = -PI/2 # right 90 degrees
var right_bottom_rotation = PI # 180 degree rotation
var bottom_left_rotation = PI/2 # left 90 degrees 
var vertical_rotation = 0 # default
var horizontal_rotation = PI/2
var delete_mesh_color = Color(0, 0, 0, 0)
var ghost_mesh_color = Color(1, 1, 1, .4)
var grid_offset = Vector3(-0.5, -0.5, 0.0)
var current_path = {} # Dictionary of Vector2 -> Vector2 (value x is key into mesh, and y is 0 for paths and 1 for corners)
var temp_path_ghost # true or false based on if a temp path ghost is currently being generated
var temp_path_ghost_i





signal size_changed # TODO: add parameter and link to the drawing pane if necessary
signal pause_stick_movement # TODO: link to locomotion.gd
signal resume_stick_movement # TODO: link to locomotion.gd


# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	camera = %XRCamera3D
	path_multi_mesh = find_child("PathMultiMesh")
	corner_multi_mesh = find_child("CornerMultiMesh")
	cursor = find_child("") # TODO: instanciate
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# (Transform)
	# If grip_pressed:
	#   Position update to node_currently_tracking
	# 	Rotation update to look at XR_Camera
	#   If grip_pressed and input is recieved from active controller's stick:
	#     Scale the map by the input_vector multiplied by the scaling speed vector
	#   Move the cursor
	#   Time the double click if we are currently doing so
	#   If dragging
	#     Float the block the user is dragging above the others and create a transparent clone where it would go when released
	#     Draggin ghost
	#   Elif pathing
	#     If just moved to a new block, update the path
	#     Pathing ghost
	#   Else (not pathing)
	#     Room queued ghost
	#     Start path ghost


	if grip_pressed:
		self.global_position = node_currently_tracking.global_position
		self.rotation = node_currently_tracking.rotation
		if grip_pressed and input_vector.length() > scaling_deadzone and (self.scale.x < self.max_scale.x and self.scale.y < self.max_):
			self.scale = self.scale + Vector3(scaling_speed.x * input_vector.x, scaling_speed.y * input_vector.y, 0.0)
			size_changed.emit()

		# Right controller cursor update
		if node_currently_tracking == left_controller:
			drawing_plane = Plane((left_controller.global_position - camera.global_position).normalized(), left_controller.global_position)
			cursor.global_position = drawing_plane.project(right_controller.global_position)
			cursor.find_child("Laser").global_scale = cursor_position.distance_to(right_controller)
			block_position  = (cursor.global_position - left_controller.global_position).ceil()

		# Left controller cursor update
		else:
			drawing_plane = Plane((right_controller.global_position - camera.global_position).normalized(), right_controller.global_position)
			cursor.global_position = drawing_plane.project(left_controller.global_position)
			cursor.find_child("Laser").global_scale = cursor_position.distance_to(left_controller)
			block_position  = (cursor.global_position - right_controller.global_position).ceil()

		# Double click timing
		if double_click_timing:
			double_click_timer += delta
			if double_click_timer > double_click_window:
				double_click_timing = false
		
		# Dragging
		if dragging:
			dragging_room.global_position = cursor.global_position + Vector3(0, 0, dragging_float_height)
			#Dragging Ghost
			if valid_block():
				dragging_room_ghost.hide()
				dragging_room_ghost.position = cursor_block + block_height_offset + grid_offset
		
		# Pathing
		elif pathing:
			if current_path_last_block != cursor_position:
				if valid_block() and cursor_block.is_adjacent(current_path_last_block):
					# Corner revision case
					if (current_path_last_block - current_path_second_to_last_block) + current_path_last_block == cursor_block:
						# Left and Top
						if (current_path_second_to_last_block - current_path_last_block == Vector2(-1, 0) or cursor_block - current_path_last_block == Vector2(-1, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector2(0, 1) or cursor_block - current_path_last_block == Vector2(0, 1)):
							# Hide current_path_last_block
							path_multi_mesh.set_instance_color(paths.get(current_path_last_block), delete_mesh_color)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corners.size()
							corners[current_path_last_block] = i
							corner_multi_mesh.instance_count += 1
							corner_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, left_top_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector2(i, 1)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
							else:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
						# Top and Right
						if (current_path_second_to_last_block - current_path_last_block == Vector2(0, 1) or cursor_block - current_path_last_block == Vector2(0, 1)) and (current_path_second_to_last_block - current_path_last_block == Vector2(1, 0) or cursor_block - current_path_last_block == Vector2(1, 0)):
							# Hide current_path_last_block
							path_multi_mesh.set_instance_color(paths.get(current_path_last_block), delete_mesh_color)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corners.size()
							corners[current_path_last_block] = i
							corner_multi_mesh.instance_count += 1
							corner_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, top_right_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector2(i, 1)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
							else:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
						# Right and Bottom
						if (current_path_second_to_last_block - current_path_last_block == Vector2(1, 0) or cursor_block - current_path_last_block == Vector2(1, 0)) and (current_path_second_to_last_block - current_path_last_block == Vector2(0, -1) or cursor_block - current_path_last_block == Vector2(0, -1)):
							# Hide current_path_last_block
							path_multi_mesh.set_instance_color(paths.get(current_path_last_block), delete_mesh_color)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corners.size()
							corners[current_path_last_block] = i
							corner_multi_mesh.instance_count += 1
							corner_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, right_bottom_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector2(i, 1)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
							else:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
						# Bottom and Left
						if (current_path_second_to_last_block - current_path_last_block == Vector2(0, -1) or cursor_block - current_path_last_block == Vector2(0, -1)) and (current_path_second_to_last_block - current_path_last_block == Vector2(-1, 0) or cursor_block - current_path_last_block == Vector2(-1, 0)):
							# Hide current_path_last_block
							path_multi_mesh.set_instance_color(paths.get(current_path_last_block), delete_mesh_color)
							# Spawn current_path_last_block as a corner with correct orientation
							var i = corners.size()
							corners[current_path_last_block] = i
							corner_multi_mesh.instance_count += 1
							corner_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(current_path_last_block + grid_offset).rotated_local(Vector3.FORWARD, bottom_left_rotation))
							corner_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[current_path_last_block] = Vector2(i, 1)
							# Spawn straight path at cursor_block with correct orientation
							if (cursor_block - current_path_last_block).x == 0:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
							else:
								var i = paths.size()
								paths[cursor_block] = i 
								paths.instance_count += 1
								path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
								path_multi_mesh.set_instance_color(i, ghost_mesh_color)
								current_path[cursor_block] = Vector2(i, 0)
					# Normal path creation case
					else:
						if (cursor_block - current_path_last_block).x == 0:
							var i = paths.size()
							paths[cursor_block] = i 
							paths.instance_count += 1
							path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
							path_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[cursor_block] = Vector2(i, 0)
						else:
							var i = paths.size()
							paths[cursor_block] = i 
							paths.instance_count += 1
							path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
							path_multi_mesh.set_instance_color(i, ghost_mesh_color)
							current_path[cursor_block] = Vector2(i, 0)
		# Room queued ghost
		elif rooms_queued:
			room_queue.front.position = cursor_position + block_height_offset
		
		# Pathing ghost
		else:
			var adjacencies = [cursor_block + Vector2.UP, cursor_block + Vector2.DOWN, cursor_block + Vector2.LEFT, cursor_block + Vector2.RIGHT]
			var i = 0
			var spotted = false
			for x in adjacencies:
				if rooms.has(x):
					spotted = true
					if i < 2:
						var i = paths.size()
						temp_path_ghost_i = i 
						temp_path_ghost = true
						paths.instance_count += 1
						path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, vertical_rotation))
						path_multi_mesh.set_instance_color(i, ghost_mesh_color)
					else:
						var i = paths.size()
						temp_path_ghost_i = i 
						temp_path_ghost = true
						paths.instance_count += 1
						path_multi_mesh.set_instance_transform(i, cursor.transform.translated_local(cursor_block + grid_offset).rotated_local(Vector3.FORWARD, horizontal_rotation))
						path_multi_mesh.set_instance_color(i, ghost_mesh_color)

				i += 1
			if spotted = false and temp_path_ghost = true:
				path_multi_mesh.set_instance_color(temp_path_ghost_i, delete_mesh_color)
				temp_path_ghost = false
				temp_path_ghost_i = null


# Returns true or false based on if this block is available for drawing
func valid_block():
	return !(paths.has(cursor_block) or rooms.has(cursor_block))

# Attempts to place a room in the location from the queue
func place_room():
	if valid_block():


# Attempts to start dragging the current block
func start_drag():
	var room = rooms.get(cursor_block)
	if room != null:
		

# Attempts to start pathing at the current block
func start_path():
	var 
	if valid_path_start:
		current_path_last_block = cursor_block
		current_path_origin = cursor_block

# Adjusts current pathing with new information 

# Cleans up room or path dragging
func dragging_clean_up():
	# Invalid call case
	if dragging_path == null && dragging_room == null:
	   return
	# Path case
	elif dragging_room == null:
		# If current cursor block is next to a room then 
	# Room case
	else:

# TODO: attach signal from left controller
func _on_left_controller_button_pressed(name):
	if name == "grip_click" and grip_pressed != true:
		grip_pressed = true
		self.show()
		node_currently_tracking = left_controller
		pause_stick_movement.emit()
	elif name = "trigger_click":
		if node_currently_tracking == right and double_click_timing and double_click_start_block == cursor_block:
			delete_section()
		else:
			double_click_timer = 0.0
			double_click_timing = true
			double_click_start_block = cursor_block
			# place room

			# start path
			# start drag
		
		

# TODO: attach signal from right controller
func _on_right_controller_button_pressed(name):
	if name == "grip_click" and grip_pressed != true:
		grip_pressed = true
		self.show()
		node_currently_tracking = right_controller
		pause_stick_movement.emit()
	elif name = "trigger_click":


# TODO: attach signal from left controller
func _on_left_controller_button_released(name):
	if name == "grip_click":
		grip_pressed = false
		self.hide()
		resume_stick_movement.emit()
		node_currently_tracking = null
	elif name = "trigger_click":
		

# TODO: attach signal from right controller
func _on_right_controller_button_released(name):
	if name == "grip_click":
		grip_pressed = false
		self.hide()
		resume_stick_movement.emit()
		node_currently_tracking = null
	elif name = "trigger_click":
		

# TODO: attach signal from left controller
func _on_left_controller_input_vector_2_changed(name, value):
	if name == "primary":
		if grip_pressed == true and node_currently_tracking == left_controller and value.length() > scaling_deadzone:
			input_vector = value
		else:
			input_vector = Vector2(0, 0)

# TODO: attach signal from right controller
func _on_right_controller_input_vector_2_changed(name, value):
	if name == "primary":
		if grip_pressed == true and node_currently_tracking == right_controller and value.length() > scaling_deadzone:
			input_vector = value
		else:
			input_vector = Vector2(0, 0)

# TODO: attach signal from somewhere
func _on_room_explored():
	if room_index != 5:
		rooms_queued = true
		room_queue.push_front(rooms[room_index])
		room_index += 1
