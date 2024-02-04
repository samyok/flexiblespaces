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
var rooms = {} # Room array (Vector2 -> Room node dictionary)
var dragging_room # null or the room being currently dragged
var dragging_room_ghost # null or the ghost of the room being currently dragged
var dragging_float_height = Vector3(0, 0, -1.0)
var double_click_timer = 0
var double_click_timing = false
var double_click_start_room
var double_click_window = .4 # Maximum time (in seconds) between first and second click when double clicking
var room_queue = []
var rooms_queued = false
var block_height_offset = Vector3(0, 0, -0.5)
var room_list
var room_ghost_map # Dictionary of Room -> Room
var dragging = false
var rooms_total = 7 # Change when adding rooms
var overlay
var overlay_shown = false
var overlay_button
var laser
var drawn_paths = {[], [], [], [], [], [], []} # Array of paths to hide on room deletion

signal pause_stick_movement
signal resume_stick_movement

# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	camera = %XRCamera3D
	overlay = %Overlay
	cursor = find_child("Cursor")
	laser = find_child("Laser")
	room_list = [find_child("Room1"), find_child("Room2"), find_child("Room3"), find_child("Room4"), find_child("Room5"), find_child("Room6"), find_child("Room7")]
	room_ghost_map = {room_list[0]: find_child("GhostRoom1"), room_list[1]: find_child("GhostRoom2"), room_list[2]: find_child("GhostRoom3"), room_list[3]: find_child("GhostRoom4"), room_list[4]: find_child("GhostRoom5"), room_list[5]: find_child("GhostRoom6"), room_list[6]: find_child("GhostRoom7")} 
	room_queue.push_front(room_list[0])
	rooms_queued = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if node_currently_tracking != null:
		if !overlay_shown:
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
				cursor_room = cursor.position.ceil()
				cursor_room.z = 0

			# Left controller cursor update
			else:
				var map_plane = Plane((right_controller.global_position - camera.global_position).normalized(), right_controller.global_position)
				cursor.global_position = map_plane.project(left_controller.global_position)
				laser.scale = Vector3(1, 1, cursor.global_position.distance_to(left_controller.global_position)/self.scale.z)
				laser.position = Vector3(0, 0, cursor.global_position.distance_to(left_controller.global_position)/(-2*self.scale.z))
				cursor_room = cursor.position.ceil()
				cursor_room.z = 0

			# Double click timing
			if double_click_timing:
				double_click_timer += delta
				if double_click_timer > double_click_window:
					double_click_timing = false
			
			# Snapped
			# (This only happens once when the snap happens and dragging is ongoing throught this)
			if snapped:
				var recieving_node
				var snapping_node
				if snap_point_1.get_parent().get_parent() == dragging_room
					recieving_node = snap_point_2
					snapping_node = snap_point_1
				else:
					recieving_node = snap_point_1
					snapping_node = snap_point_2
				var revieving_direction

			# Drawing
			elif drawing:
				#

			# Dragging
			elif dragging:
			
			# Room queued ghost
			elif rooms_queued and valid_block():
			
		else:
			overlay.global_position = node_currently_tracking.global_position
			overlay.look_at(camera.global_position)

# Attempts to place a room in the location from the queue
func place_room():


# Attach a room to the map
func attach_room():


# Starts drawing from the currently selected snap point
func start_drawing(snap_point):
	var path = snap_point.get_parent().find_child("Path")
	var cursor_position = cursor.position + path_height_offset
	# Centers the path between the cursor and snap point
	path.position = cursor_position + ((cursor_position - snap_point.position) / 2)
	# Rotates the path to face the cursor
	# TODO: implement
	# Scales the path to stretch between the cursor and the snap point
	path.scale.z = path.position.distance_to(cursor_position) # TODO: extend this a little bit more based on the angle of cursor to where the snap_point should be so the corners of the path connection points are flush
	# Unhides the path dedicated to this snap point
	path.unhide()


# Attempts to start dragging the current block
func start_drag():


# Cleans up room dragging
func dragging_clean_up():


# Put the currently selected room onto the queue
func delete_selection():

	#Loops through drawn paths list for this room and hides them

# Hides map and shows overlay
func toggle_overlay_on():
	cancel_almost_everything()
	overlay.show()
	overlay_shown = true

# Hides overlay and shows map
func toggle_overlay_off():
	self.show()
	overlay.hide()
	overlay_shown = false

# Cleans up drawing pane and hides it, hiding all elements and terminating all pathing, dragging, or ghosts
func cancel_everything():
	self.hide()
	resume_stick_movement.emit()
	node_currently_tracking = null
	if dragging:
		dragging_clean_up()

# Cleans up drawing pane and hides it, hiding all elements and terminating all pathing, dragging, or ghosts, but doesnt stow the map
func cancel_almost_everything():
	self.hide()
	if dragging:
		dragging_clean_up()
	
# Detects snap of the areas attached to the connection points
func _on_area_3d_area_entered(area):
	if area.name == "SnapPoint":
		if snapped == false:
			print("gate")
			snapped = true
			snap_point_1 = area
		else:
			snap_point_2 = area

func _on_left_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != left_controller:
		self.show()
		node_currently_tracking = left_controller
		pause_stick_movement.emit()
	elif name == "trigger_click":
		if node_currently_tracking == right_controller:
			if double_click_timing and double_click_start_room == cursor_room and cursor_room != null and not overlay_shown:
				delete_selection()
			else:
				double_click_timer = 0.0
				double_click_timing = true
				double_click_start_room = cursor_room
				# place room
				if valid_block and rooms_queued and !dragging and !pathing:
					place_room()
				# start drag
				elif rooms.has(cursor_room) and !dragging and !pathing and !rooms_queued:
					start_drag()
	elif name == "ax_button" and not overlay_shown:
		if node_currently_tracking != null:
			toggle_overlay_on()
			overlay_button = 0
	elif name == "by_button" and not overlay_shown:
		if node_currently_tracking != null:
			toggle_overlay_on()
			overlay_button = 1

func _on_right_controller_button_pressed(name):
	if name == "grip_click" and node_currently_tracking != right_controller:
		self.show()
		node_currently_tracking = right_controller
		pause_stick_movement.emit()
	elif name == "trigger_click":
		if node_currently_tracking == left_controller:
			if double_click_timing and double_click_start_room == cursor_room and cursor_room != null and not overlay_shown:
				delete_selection()
			else:
				double_click_timer = 0.0
				double_click_timing = true
				double_click_start_room = cursor_room
				# place room
				if valid_block and rooms_queued and !dragging and !pathing:
					place_room()
				# start drag
				elif rooms.has(cursor_room) and !dragging and !pathing and !rooms_queued:
					start_drag()
				# start path
				elif temp_path_ghost != null and !rooms_queued:
					start_path()
	elif name == "ax_button" and not overlay_shown:
		if node_currently_tracking != null:
			toggle_overlay_on()
			overlay_button = 2
	elif name == "by_button" and not overlay_shown:
		if node_currently_tracking != null:
			toggle_overlay_on()
			overlay_button = 3


func _on_left_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == left_controller:
		cancel_everything()
	elif name == "trigger_click":
		if node_currently_tracking == right_controller:
			if dragging:
				dragging_clean_up()
			elif pathing:
				pathing_clean_up()
	elif name == "ax_button" and overlay_shown and overlay_button == 0:
		if node_currently_tracking != null:
			toggle_overlay_off()
	elif name == "by_button" and overlay_shown and overlay_button == 1:
		if node_currently_tracking != null:
			toggle_overlay_off()
		

func _on_right_controller_button_released(name):
	if name == "grip_click" and node_currently_tracking == right_controller:
		cancel_everything()
	elif name == "trigger_click":
		if node_currently_tracking == left_controller:
			if dragging:
				dragging_clean_up()
			elif pathing:
				pathing_clean_up()
	elif name == "ax_button" and overlay_shown and overlay_button == 2:
		if node_currently_tracking != null:
			toggle_overlay_off()
	elif name == "by_button" and overlay_shown and overlay_button == 3:
		if node_currently_tracking != null:
			toggle_overlay_off()
		

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
	rooms_queued = true
	room_queue.push_back(room_list[room])
