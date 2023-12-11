extends Node3D

var is_open := false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# has collision with player?
	var user = get_node("%XRUser") as Area3D
	var collision_area = $Area3D as Area3D


	if not is_open and collision_area.overlaps_area(user):
		is_open = true
		print("OPENING DOOR")

		$AnimationPlayer.play("door_open")
