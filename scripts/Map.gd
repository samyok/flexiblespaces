extends Node3D

var node_currently_tracking # updates the position and rotation of the Map to this node's transform in _process
var camera
var left_controller
var right_controller
var grip_pressed = false
var last_cursor_position = Vector2(0.0, 0.0)
var input_vector = Vector2(0.0, 0.0)
var scaling_deadzone = .2
var scaling_speed = 1.0
var max_scale = 4.0
var cursor
var cursor_block
var active
var path_multi_mesh
var corner_multi_mesh
var rooms # Room array (Vector2 -> Room node dictionary)
var paths # Path array (Vector2 -> instance id)
var corners # Path corner array (Vector2 -> instance id)
var adjacencies # Vector3 array (path index, room id1, room id 2)
var dragging_room # null or the room being currently dragged
var dragging_path # null or the path being currently dragged
var path_ghost_transparency = .4 # Transparency (0 to 1) of the pending path
var valid_path_start
var current_path_origin
var current_path_last_block
var double_click_timer = 0
var double_click_timing = false
var double_click_start_block
var double_click_window = .4 # Maximum time (in seconds) between first and second click when double clicking
var room_queue = []
var rooms_queued = false
var room_index = 0



signal size_changed # TODO: add parameter and link to the drawing pane if necessary
signal pause_stick_movement # TODO: link to locomotion.gd
signal resume_stick_movement # TODO: link to locomotion.gd
signal cursor_position_changed # TODO: add parameter and link to the drawing pane
signal cursor_click_started  # TODO: link to the drawing pane
signal cursor_click_ended # TODO: link to the drawing pane
signal cursor_double_click # TODO: link to the drawing pane
signal show_screen # TODO: link to the drawing pane
signal hide_screen # TODO: link to the drawing pane


# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	camera = %XRCamera3D
	node_currently_tracking = null
	path_multi_mesh = find_child("PathMultiMesh")
	corner_multi_mesh = find_child("CornerMultiMesh")
	rooms = [find_child("Room1"), find_child("Room2"), find_child("Room3"), find_child("Room4"), find_child("Room5")]
	paths = []
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
			var drawing_plane = Plane((left_controller.position - camera.position).normalized(), left_controller.position)
			cursor.position = drawing_plane.project(right_controller.position)
			cursor.find_child("Laser").global_scale = cursor_position.distance_to(right_controller)
			block_position  = (cursor.position - left_controller.position).ceil()

		# Left controller cursor update
		else:
			var drawing_plane = Plane((right_controller.position - camera.position).normalized(), right_controller.position)
			cursor.position = drawing_plane.project(left_controller.position)
			cursor.find_child("Laser").global_scale = cursor_position.distance_to(left_controller)
			block_position  = (cursor.position - right_controller.position).ceil()

		# Double click timing
		if double_click_timing:
			double_click_timer += delta
			if double_click_timer > double_click_window:
				double_click_timing = false
		
		# Dragging
		if 
		
		# Pathing

		# Dragging or room queued ghost

		# Path start or pathing ghost

# Attempts to place a room in the location from the queue
func place_room():

# Attempts to start dragging the current block
func start_drag():

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
		if double_click_timing and double_click_start_block == cursor_block:
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
	elif name = "trigger_click":
		

# TODO: attach signal from right controller
func _on_right_controller_button_released(name):
	if name == "grip_click":
		grip_pressed = false
		self.hide()
		resume_stick_movement.emit()
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
