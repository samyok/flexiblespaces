extends Node3D

@export var max_speed:= 5
@export var dead_zone := 0.2

@export var smooth_turn_speed:= 45.0
@export var smooth_turn_dead_zone := 0.2
@export var snap_turn_dead_zone := 0.9
@export var snap_turn_reset_zone := 0.1
var snap_turn_active := true

enum LocomotionMethod {controller_turn, controller_direction}
enum TurnMethod {snap, smooth}

@export var locomtion_method := LocomotionMethod.controller_turn
@export var turn_method := TurnMethod.smooth

var input_vector:= Vector2.ZERO
var camera: XRCamera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_node("%XRCamera3D")
	set_physics_process( true )

func toggle_locomotion_method():
	if locomtion_method == LocomotionMethod.controller_turn:
		locomtion_method = LocomotionMethod.controller_direction
	elif locomtion_method == LocomotionMethod.controller_direction:
		locomtion_method = LocomotionMethod.controller_turn
	print("new locomotion_method: ", locomtion_method)

func toggle_turn_method():
	if turn_method == TurnMethod.smooth:
		turn_method = TurnMethod.snap
	elif turn_method == TurnMethod.snap:
		turn_method = TurnMethod.smooth
	print("new turn_method: ", turn_method)

func controller_turn(delta):
	# Forward translation
	if self.input_vector.y > self.dead_zone || self.input_vector.y < -self.dead_zone:
		var movement_vector = Vector3(0, 0, max_speed * -self.input_vector.y * delta)
		self.position += movement_vector.rotated(Vector3.UP, camera.global_rotation.y)

	if turn_method == TurnMethod.smooth: 
		smooth_turn(delta)
	elif turn_method == TurnMethod.snap:
		snap_turn()

	
func smooth_turn(delta):
	# Smooth turn
	if self.input_vector.x > self.smooth_turn_dead_zone || self.input_vector.x < -self.smooth_turn_dead_zone:
		# move to the position of the camera
		self.translate(camera.position)
		# rotate about the camera's position
		self.rotate(Vector3.UP, deg_to_rad(smooth_turn_speed) * -self.input_vector.x * delta)
		# reverse the translation to move back to the original position
		self.translate(camera.position * -1)

func snap_turn():
	"""
	if the input_vector.x is greater than the snap_turn_dead_zone, then rotate 45 degrees,
	otherwise if the input_vector.x is less than the snap_turn_reset_zone, then reset the snap_turn_active flag
	"""
	if not snap_turn_active and abs(self.input_vector.x) < snap_turn_reset_zone:
		snap_turn_active = true
	elif snap_turn_active and abs(self.input_vector.x) > snap_turn_dead_zone:
		snap_turn_active = false
		var direction = 1 if self.input_vector.x > 0 else -1
		self.rotate(Vector3.UP, deg_to_rad(45) * direction)



func controller_direction(delta):
	# face the same direction the controller is facing
	var left_controller = get_node("%LeftController")
	var controller_rotation = left_controller.rotation_degrees + self.rotation_degrees
	var movement_direction = Vector3(0, controller_rotation.y, 0)
	# print("movement_direction ", movement_direction)

	# Forward translation in the movement_direction, but only use the y component of the movement_direction
	if abs(self.input_vector.y) > self.dead_zone:
		var speed = max_speed * self.input_vector.y * delta
		var movement_vector = Vector3(sin(deg_to_rad(movement_direction.y)), 0, cos(deg_to_rad(movement_direction.y))) * speed
		self.position -= movement_vector 

func process_input(input_name: String, input_value: Vector2):
	if input_name == "primary":
		input_vector = input_value


func button_pressed(button_name):
	if button_name == "ax_button":
		toggle_locomotion_method()

	if button_name == "by_button":
		toggle_turn_method()

func reset_user_position():
	self.position = Vector3.ZERO

func is_touching_enemy():
	var user: Area3D = get_node("%XRUser")
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if user.overlaps_area(enemy as Area3D):
			return true
	return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# if is_touching_enemy():
	# 	reset_user_position()
	# 	return
	
	if locomtion_method == LocomotionMethod.controller_turn:
		controller_turn(delta)
	elif locomtion_method == LocomotionMethod.controller_direction:
		controller_direction(delta)
	
func _physics_process(_delta): 
	if is_touching_enemy():
		reset_user_position()
		return