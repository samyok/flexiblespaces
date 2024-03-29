extends Node3D

var paths
var current_path
var walls
var material
var stone_texture

var EMPTY = 0
var VERTICAL = 1
var HORIZONTAL = 2
var TOP_AND_RIGHT = 3
var RIGHT_AND_BOTTOM = 4
var BOTTOM_AND_LEFT = 5
var LEFT_AND_TOP = 6
var ALL_BUT_TOP = 7
var ALL_BUT_RIGHT = 8
var ALL_BUT_BOTTOM = 9
var ALL_BUT_LEFT = 10

var TOP_WALL_OFFSET = Vector3(.5, 1.5, 0)
var RIGHT_WALL_OFFSET = Vector3(1, 1.5, .5)
var BOTTOM_WALL_OFFSET = Vector3(.5, 1.5, 1)
var LEFT_WALL_OFFSET = Vector3(0, 1.5, 0.5)

var HORIZONTAL_WALL_OFFSET = Vector3(0, 0, 0)
var VERTICAL_WALL_OFFSET = Vector3(0, PI/2, 0)

var path_grids = [
	[
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  6,  2, 10,  0,  0,  0],
		[ 0,  0,  5,  2,  3,  0,  0,  0],
		[ 0,  9,  0,  0,  1,  0,  0,  0],
		[ 0,  1,  0,  6,  4,  0,  0,  0],
		[ 0,  5,  2,  4,  0,  0,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0]
	],
	[
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  8,  2,  3,  0,  0],
		[ 0,  0,  0,  6,  2,  4,  0,  0],
		[ 0,  0,  0,  1,  0,  0,  9,  0],
		[ 0,  0,  0,  5,  3,  0,  1,  0],
		[ 0,  0,  0,  0,  5,  2,  4,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0]
	],
	# Path 12
	[
		[ 0,  0,  0,  0,  0,  0,  0,  0],
		[ 0,  0,  0,  8,  2,  3,  0,  0],
		[ 0,  0,  0,  0,  0,  1,  0,  0],
		[ 0,  6,  2,  2,  2,  4,  0,  0],
		[ 0,  5,  2,  2,  2,  3,  0,  0],
		[ 0,  0,  0,  0,  0,  1,  0,  0],
		[ 0,  0,  0,  8,  2,  4,  0,  0],
		[ 0,  0,  0,  0,  0,  0,  0,  0]
	]
]

func _ready():
	material = preload("res://textures/cobblestone.tres")
	walls = []
	#paths = [self.find_child("Path1"), self.find_child("Path5"), self.find_child("Path3"), self.find_child("Path4"), self.find_child("Path2"), self.find_child("Path6"), self.find_child("Path7"), self.find_child("Path8"), self.find_child("Path12"), self.find_child("Path10"), self.find_child("Path11"), self.find_child("Path9")]

func draw_path(start_door, end_door):
	var rand = 0
	# North
	if start_door == 0:
		# Rotate
		self.rotation.y = 0
		# Right
		if end_door == 3:
			create_walls(0)
		# Straight
		elif end_door == 2:
			create_walls(2)
		# Left
		else:
			create_walls(1)

	# East
	elif start_door == 1:
		# Rotate
		self.rotation.y = -PI/2
		# Right
		if end_door == 0:
			create_walls(0)
		# Straight
		elif end_door == 3:
			create_walls(2)
		# Left
		else:
			create_walls(1)

	# South
	elif start_door == 2:
		# Rotate
		self.rotation.y = PI
		# Right
		if end_door == 1:
			create_walls(0)
		# Straight
		elif end_door == 0:
			create_walls(2)
		# Left
		else:
			create_walls(1)

	# West
	else:
		# Rotate
		self.rotation.y = PI/2
		# Right
		if end_door == 2:
			create_walls(0)
		# Straight
		elif end_door == 1:
			create_walls(2)
		# Left
		else:
			create_walls(1)

func create_walls(path_number):
	var path_grid = path_grids[path_number]
	
	# Loop through the middle 6x6 of the path grid (which is an 8x8)
	for i in (path_grid.size()):
		if i != 0 or i != 7:
			for j in (path_grid[0].size()):
				if j != 0 or j != 7:
					if path_grid[i][j] != EMPTY:
						var position_offset = Vector3(-3, 0, -3)
						var rotation_offset = Vector3(0, 0, 0)
						print(str(position_offset + Vector3(i-1, 0, j-1)) + ": " + str(path_grid[i][j]))
						create_hallway_segment(position_offset + Vector3(j-1, 0, i-1), path_grid[i][j])

func create_hallway_segment(position_offset, type):
	# Bottom
	if type == ALL_BUT_LEFT or type == ALL_BUT_RIGHT or type == ALL_BUT_TOP or type == BOTTOM_AND_LEFT or type == RIGHT_AND_BOTTOM or type == HORIZONTAL:
		var bottom_wall = MeshInstance3D.new()
		bottom_wall.mesh = PlaneMesh.new()
		bottom_wall.mesh.set_size(Vector2(1, 3))
		bottom_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
		bottom_wall.position = BOTTOM_WALL_OFFSET + position_offset
		bottom_wall.rotation = HORIZONTAL_WALL_OFFSET
		bottom_wall.mesh.material = material
		self.add_child(bottom_wall)
		walls.push_front(bottom_wall)
	# Left
	if type == ALL_BUT_BOTTOM or type == ALL_BUT_RIGHT or type == ALL_BUT_TOP or type == BOTTOM_AND_LEFT or type == LEFT_AND_TOP or type == VERTICAL:
		var left_wall = MeshInstance3D.new()
		left_wall.mesh = PlaneMesh.new()
		left_wall.mesh.set_size(Vector2(1, 3))
		left_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
		left_wall.position = LEFT_WALL_OFFSET + position_offset
		left_wall.rotation = VERTICAL_WALL_OFFSET
		left_wall.mesh.material = material
		self.add_child(left_wall)
		walls.push_front(left_wall)
	# Right
	if type == ALL_BUT_BOTTOM or type == ALL_BUT_LEFT or type == ALL_BUT_TOP or type == RIGHT_AND_BOTTOM or type == TOP_AND_RIGHT or type == VERTICAL:
		var right_wall = MeshInstance3D.new()
		right_wall.mesh = PlaneMesh.new()
		right_wall.mesh.set_size(Vector2(1, 3))
		right_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
		right_wall.position = RIGHT_WALL_OFFSET  + position_offset
		right_wall.rotation = VERTICAL_WALL_OFFSET
		right_wall.mesh.material = material
		self.add_child(right_wall)
		walls.push_front(right_wall)
	# Top
	if type == ALL_BUT_BOTTOM or type == ALL_BUT_LEFT or type == ALL_BUT_RIGHT or type == TOP_AND_RIGHT or type == LEFT_AND_TOP or type == HORIZONTAL:
		var top_wall = MeshInstance3D.new()
		top_wall.mesh = PlaneMesh.new()
		top_wall.mesh.set_size(Vector2(1, 3))
		top_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
		top_wall.position = TOP_WALL_OFFSET + position_offset
		top_wall.rotation = HORIZONTAL_WALL_OFFSET
		top_wall.mesh.material = material
		self.add_child(top_wall)
		walls.push_front(top_wall)

func _on_entered_hallway(start_door, end_door):
	draw_path(start_door, end_door)

func _on_exited_hallway():
	for wall in walls:
		self.remove_child(wall)
		print(self.get_child_count())
	walls = []
