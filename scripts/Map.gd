extends Node3D

var in_hand = false
var dominant_hand = "left" # "left" or "right"
var node_currently_tracking # updates the position and rotation of the Map to this node's transform in _process
var lerp_start_node 
var lerp_end_node 
var lerp_from_hip = false
var lerp_to_hip = false
var lerp_in_progress = false # true or false
var lerp_speed = 1.0 # time (in seconds) for the map to lerp between points
var current_alpha = 0.0 # progress from 0.0-1.0 of current lerp
var left_controller
var right_controller 
var left_hip
var right_hip
var active_hand_grip_down = false
var last_movement_direction
var input_vector = Vector2(0.0, 0.0)
var scaling_deadzone = .2
var scaling_speed = Vector2(1.0, 1.0)
var max_scale = Vector2(4.0, 4.0)


signal hip_hitbox_show # TODO: link to both hip hitboxes
signal hip_hitbox_hide # TODO: link to both hip hitboxes
signal size_changed # TODO: link to the drawing pane if necessary
signal pause_stick_movement # TODO: link to locomotion.gd
signal resume_stick_movement # TODO: link to locomotion.gd


# Called when the node enters the scene tree for the first time.
func _ready():
	left_controller = %LeftController
	right_controller = %RightController
	left_hip = %LeftHip
	right_hip = %RightHip
	node_currently_tracking = right_hip


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	# (Movement)
	# If lerping:
	#   Lerp between positions of lerp_start_node and lerp_end_node
	# Else:
	#   Position update to node_currently_tracking
	# (Rotation)
	# If lerping: 
	#   Lerp between lookat(XR_Camera) and hip_direction
	# Elif in a hand:
	# 	Rotation update to look at XR_Camera
	# Else:
	# 	Rotation update matches orthogonal to last_movement_direction and Up vector
  # (Scaling)
	# If active_hand_grip_down and input is recieved from active controller's stick:
	#   Scale the map by the input_vector multiplied by the scaling speed vector
	if lerp_in_progress:
		current_alpha += lerp_speed * delta
		if current_alpha > 1:
			current_alpha = 1
		self.global_position = lerp_start_node.global_position.lerp(lerp_end_node.global_position, current_alpha)
		if lerp_from_hip:
			var hip_rotation = last_movement_direction * PI * 2
			self.rotation = hip_rotation.lerp(lerp_end_node.rotation, current_alpha)
		elif lerp_to_hip:
			var hip_rotation = last_movement_direction * PI * 2
			self.rotation = lerp_start_node.rotation.lerp(hip_rotation, current_alpha)
		else:
			self.rotation = lerp_start_node.rotation.lerp(lerp_end_node.rotation, current_alpha)
		if current_alpha == 1:
			clean_up_lerp()
	else:
		self.global_position = node_currently_tracking.global_position
		if not in_hand:
			self.rotation = last_movement_direction * PI * 2
		else:
			self.rotation = node_currently_tracking.rotation
	if active_hand_grip_down and input_vector.length() > 0 and (self.scale.x < self.max_scale.x and self.scale.y < self.max_):
		self.scale = self.scale + Vector3(scaling_speed.x * input_vector.x, scaling_speed.y * input_vector.y, 0.0)
		size_changed.emit()

func initiate_lerp(to):
	if not lerp_in_progress:
		if not in_hand:
			lerp_from_hip = true
		if to == "left":
			lerp_in_progress = true
			lerp_start_node = node_currently_tracking
			lerp_end_node = left_controller
			in_hand = true
		elif to == "right":
			lerp_in_progress = true
			lerp_start_node = node_currently_tracking
			lerp_end_node = right_controller
			in_hand = true
		elif to == "left_hip":
			lerp_in_progress = true
			lerp_start_node = node_currently_tracking
			lerp_end_node = left_hip
			in_hand = false
			lerp_to_hip = true
		elif to == "right_hip":
			lerp_in_progress = true
			lerp_start_node = node_currently_tracking
			lerp_end_node = right_hip
			in_hand = false
			lerp_to_hip = true

func clean_up_lerp():
	current_alpha = 0
	node_currently_tracking = lerp_end_node
	lerp_in_progress = false
	lerp_start_node = null
	lerp_end_node = null
	lerp_from_hip = false
	lerp_to_hip = false

func _on_left_controller_button_pressed(name):
	if name == "grip_click":
		active_hand_grip_down = true
		if node_currently_tracking != left_controller:
			initiate_lerp("left")
		else:
			pause_stick_movement.emit()
			hip_hitbox_show.emit()

func _on_right_controller_button_pressed(name):
	if name == "grip_click":
		active_hand_grip_down = true
		if node_currently_tracking != right_controller:
			initiate_lerp("right")
		else:
			pause_stick_movement.emit()
			hip_hitbox_show.emit()


# TODO: attach signal from left controller
func _on_left_controller_button_released(name):
	if name == "grip_click":
		active_hand_grip_down = false
		hip_hitbox_hide.emit()
		resume_stick_movement.emit()

# TODO: attach signal from right controller
func _on_right_controller_button_released(name):
	if name == "grip_click":
		active_hand_grip_down = false
		hip_hitbox_hide.emit()
		resume_stick_movement.emit()

# TODO: attach signal from locomation
func _on_movement_direction_changed(new_direction):
	last_movement_direction = new_direction

# TODO: attach signal from left hip hitbox
func _on_left_hip_area_3d_area_entered(area):
	if area == self.find_child("MapHitbox"):
		if active_hand_grip_down:
			input_vector = Vector2(0.0, 0.0)
			initiate_lerp("left_hip")

# TODO attach signal from right hip hitbox
func _on_right_hip_area_3d_area_entered(area):
	if area == self.find_child("MapHitbox"):
		if active_hand_grip_down:
			input_vector = Vector2(0.0, 0.0)
			initiate_lerp("right_hip")

# TODO: attach signal from left controller
func _on_left_controller_input_vector_2_changed(name, value):
	if name == "primary" and in_hand == true and node_currently_tracking.ID == left_controller.ID and value.length() > scaling_deadzone:
		input_vector = value

# TODO: attach signal from right controller
func _on_right_controller_input_vector_2_changed(name, value):
	if name == "primary" and in_hand == true and node_currently_tracking.ID == right_controller.ID and value.length() > scaling_deadzone:
		input_vector = value
			
