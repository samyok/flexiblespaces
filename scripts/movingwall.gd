extends Node3D


@export var speed = 1
@export var max_x = 2
@export var min_x = -8
var direction = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	self.position.x += speed * delta * direction
	if self.position.x > max_x:
		direction = -1
	elif self.position.x < min_x:
		direction = 1