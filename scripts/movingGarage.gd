extends Node3D


@export var speed = 1
@export var max_y = 6
@export var min_y = -4
var direction = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position.y += speed * delta * direction
	if self.position.y > max_y:
		direction = -1
	elif self.position.y < min_y:
		direction = 1