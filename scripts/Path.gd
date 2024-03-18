extends Node3D

var paths
var current_path
var walls
var material
var stone_texture

var EMPTY = 0
var VERTICAL = 1
var HORIZONTAL = 2
var TOP_RIGHT = 3
var RIGHT_BOTTOM = 4
var BOTTOM_LEFT = 5
var LEFT_TOP = 6
var TOP = 7
var RIGHT = 8
var BOTTOM = 9
var LEFT = 10
var TOP_BOTTOM_LEFT_HALF = 11
var TOP_BOTTOM_RIGHT_HALF = 12
var LEFT_RIGHT_TOP_HALF = 13
var LEFT_RIGHT_BOTTOM_HALF = 14
var BOTTOM_TOP_LEFT_HALF = 15
var BOTTOM_TOP_RIGHT_HALF = 16
var RIGHT_LEFT_TOP_HALF = 17
var RIGHT_LEFT_BOTTOM_HALF = 18
var LEFT_BOTTOM_TOP_LEFT_HALF = 19
var BOTTOM_RIGHT_TOP_RIGHT_HALF = 20
var TOP_RIGHT_LEFT_TOP_HALF = 21
var BOTTOM_RIGHT_LEFT_BOTTOM_HALF = 22
var TOP_LEFT_BOTTOM_LEFT_HALF = 23
var TOP_RIGHT_BOTTOM_RIGHT_HALF = 24
var TOP_LEFT_RIGHT_TOP_HALF = 25
var BOTTOM_LEFT_RIGHT_BOTTOM_HALF = 26

var TOP_WALL_OFFSET = Vector3(.5, 1.5, 0)
var RIGHT_WALL_OFFSET = Vector3(1, 1.5, .5)
var BOTTOM_WALL_OFFSET = Vector3(.5, 1.5, 1)
var LEFT_WALL_OFFSET = Vector3(0, 1.5, 0.5)

var LEFT_HALF_OFFSET = Vector3(-0.25, 0, 0)
var RIGHT_HALF_OFFSET = Vector3(0.25, 0, 0)
var TOP_HALF_OFFSET = Vector3(0, 0, -0.25)
var BOTTOM_HALF_OFFSET = Vector3(0, 0, 0.25)

var HORIZONTAL_WALL_OFFSET = Vector3(0, 0, 0)
var VERTICAL_WALL_OFFSET = Vector3(0, PI/2, 0)

var WHOLE_SIZE = Vector2(1, 3)
var HALF_SIZE = Vector2(0.5, 3)

var DOOR1 = 0
var THRESHOLD1 = 1
var MIDDLE_BIT = 2
var THRESHOLD2 = 3
var DOOR2 = 4

var path_grids = [
	[# Path 1
		[ # Door 1
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  6, 11, 24,  0,  0,  0],
			[ 0,  0, 10,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ #Threshold 1
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  9,  2,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Middle bit
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  3,  0,  0,  0],
			[ 0,  0,  0,  0,  1,  0,  0,  0],
			[ 0,  0,  0,  6,  4,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Threshold 2
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  7,  4,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Door 2
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0, 25,  0,  0,  0,  0,  0,  0],
			[ 0, 14,  0,  0,  0,  0,  0,  0],
			[ 0,  5,  9,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		]
	],
	[# Path 2
		[ # Door 1
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0, 23, 12,  3,  0,  0],
			[ 0,  0,  0,  0,  0,  8,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Threshold 1
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  2,  9,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Middle part
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  6,  0,  0,  0,  0],
			[ 0,  0,  0,  1,  0,  0,  0,  0],
			[ 0,  0,  0,  5,  3,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Threshold 2
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  5,  9,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Door 2
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0, 21,  0],
			[ 0,  0,  0,  0,  0,  0, 18,  0],
			[ 0,  0,  0,  0,  0,  7,  4,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		]
	],
	[# Path 12
		[ # Door 1
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0, 23, 12,  3,  0,  0],
			[ 0,  0,  0,  0,  0,  8,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Threshold 1
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0, 10,  0,  0],
			[ 0,  0,  0,  0,  0,  4,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Middle part
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  6,  2,  2,  2,  0,  0,  0],
			[ 0,  5,  2,  2,  2,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Threshold 2
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  3,  0,  0],
			[ 0,  0,  0,  0,  0, 10,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		],
		[ # Door 2
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0],
			[ 0,  0,  0,  0,  0,  8,  0,  0],
			[ 0,  0,  0, 19, 16,  4,  0,  0],
			[ 0,  0,  0,  0,  0,  0,  0,  0]
		]
	]
]

func _ready():
	material = preload("res://textures/cobblestone.tres")
	walls = [[], [], [], [], []]

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
	for l in range(5):
		var path_grid = path_grids[path_number][l]
		
		# Loop through the middle 6x6 of the path grid (which is an 8x8)
		for i in (path_grid.size()):
			if i != 0 or i != 7:
				for j in (path_grid[0].size()):
					if j != 0 or j != 7:
						if path_grid[i][j] != EMPTY:
							var position_offset = Vector3(-3, 0, -3)
							var rotation_offset = Vector3(0, 0, 0)
							print(str(position_offset + Vector3(i-1, 0, j-1)) + ": " + str(path_grid[i][j]))
							create_hallway_segment(position_offset + Vector3(j-1, 0, i-1), path_grid[i][j], l)

func create_hallway_segment(position_offset, type, segment):
	print("Creating hallway segments at: " + str(position_offset))
	if type != 0:
		# Bottom
		if type == BOTTOM_RIGHT_LEFT_BOTTOM_HALF or type == BOTTOM_RIGHT_TOP_RIGHT_HALF or type == BOTTOM_TOP_LEFT_HALF or type == BOTTOM_LEFT_RIGHT_BOTTOM_HALF or type == BOTTOM_TOP_RIGHT_HALF or type == LEFT_BOTTOM_TOP_LEFT_HALF or type == BOTTOM_LEFT or type == RIGHT_BOTTOM or type == HORIZONTAL or type == BOTTOM:
			var bottom_wall = MeshInstance3D.new()
			bottom_wall.mesh = PlaneMesh.new()
			bottom_wall.mesh.set_size(WHOLE_SIZE)
			bottom_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			bottom_wall.position = BOTTOM_WALL_OFFSET + position_offset
			bottom_wall.rotation = HORIZONTAL_WALL_OFFSET
			bottom_wall.mesh.material = material
			self.add_child(bottom_wall)
			walls[segment].push_front(bottom_wall)
			print("\tCreating Bottom wall at: " + str(BOTTOM_WALL_OFFSET + position_offset))
			
			
		# Left
		if type == LEFT_BOTTOM_TOP_LEFT_HALF or type == LEFT_RIGHT_BOTTOM_HALF or type == LEFT_RIGHT_TOP_HALF or type == TOP_LEFT_BOTTOM_LEFT_HALF or type == TOP_LEFT_RIGHT_TOP_HALF or type == LEFT or type == BOTTOM_LEFT or type == LEFT_TOP or type == VERTICAL:
			var left_wall = MeshInstance3D.new()
			left_wall.mesh = PlaneMesh.new()
			left_wall.mesh.set_size(WHOLE_SIZE)
			left_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			left_wall.position = LEFT_WALL_OFFSET + position_offset
			left_wall.rotation = VERTICAL_WALL_OFFSET
			left_wall.mesh.material = material
			self.add_child(left_wall)
			walls[segment].push_front(left_wall)
			print("\tCreating Left wall at: " + str(LEFT_WALL_OFFSET + position_offset))
			
		# Right
		if type == RIGHT_LEFT_BOTTOM_HALF or type == RIGHT_LEFT_TOP_HALF or type == TOP_RIGHT_BOTTOM_RIGHT_HALF or type == TOP_RIGHT_LEFT_TOP_HALF or type == BOTTOM_RIGHT_LEFT_BOTTOM_HALF or type == BOTTOM_RIGHT_TOP_RIGHT_HALF or type == RIGHT_BOTTOM or type == TOP_RIGHT or type == VERTICAL or type == RIGHT:
			var right_wall = MeshInstance3D.new()
			right_wall.mesh = PlaneMesh.new()
			right_wall.mesh.set_size(WHOLE_SIZE)
			right_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			right_wall.position = RIGHT_WALL_OFFSET  + position_offset
			right_wall.rotation = VERTICAL_WALL_OFFSET
			right_wall.mesh.material = material
			self.add_child(right_wall)
			walls[segment].push_front(right_wall)
			print("\tCreating Right wall at: " + str(RIGHT_WALL_OFFSET + position_offset))
			
		# Top
		if type == TOP_BOTTOM_LEFT_HALF or type == TOP_BOTTOM_RIGHT_HALF or type == TOP_LEFT_BOTTOM_LEFT_HALF or type == TOP_LEFT_RIGHT_TOP_HALF or type == TOP_RIGHT_BOTTOM_RIGHT_HALF or type == TOP_RIGHT_LEFT_TOP_HALF or type == TOP_RIGHT or type == LEFT_TOP or type == HORIZONTAL or type == TOP:
			var top_wall = MeshInstance3D.new()
			top_wall.mesh = PlaneMesh.new()
			top_wall.mesh.set_size(WHOLE_SIZE)
			top_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			top_wall.position = TOP_WALL_OFFSET + position_offset
			top_wall.rotation = HORIZONTAL_WALL_OFFSET
			top_wall.mesh.material = material
			self.add_child(top_wall)
			walls[segment].push_front(top_wall)
			print("\tCreating Top wall at: " + str(TOP_WALL_OFFSET + position_offset))
		
		# Top Left Half
		if type == BOTTOM_TOP_LEFT_HALF or type == LEFT_BOTTOM_TOP_LEFT_HALF:
			var top_wall = MeshInstance3D.new()
			top_wall.mesh = PlaneMesh.new()
			top_wall.mesh.set_size(HALF_SIZE)
			top_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			top_wall.position = TOP_WALL_OFFSET + position_offset + LEFT_HALF_OFFSET
			top_wall.rotation = HORIZONTAL_WALL_OFFSET
			top_wall.mesh.material = material
			self.add_child(top_wall)
			walls[segment].push_front(top_wall)
			print("\tCreating Top Left Half wall at: " + str(TOP_WALL_OFFSET + position_offset + LEFT_HALF_OFFSET))
		
		# Top Right Half
		if type == BOTTOM_TOP_RIGHT_HALF or type == BOTTOM_RIGHT_TOP_RIGHT_HALF:
			var top_wall = MeshInstance3D.new()
			top_wall.mesh = PlaneMesh.new()
			top_wall.mesh.set_size(HALF_SIZE)
			top_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			top_wall.position = TOP_WALL_OFFSET + position_offset + RIGHT_HALF_OFFSET
			top_wall.rotation = HORIZONTAL_WALL_OFFSET
			top_wall.mesh.material = material
			self.add_child(top_wall)
			walls[segment].push_front(top_wall)
			print("\tCreating Top Right Half wall at: " + str(TOP_WALL_OFFSET + position_offset + RIGHT_HALF_OFFSET))
		
		# Left Top Half
		if type == RIGHT_LEFT_TOP_HALF or type == TOP_RIGHT_LEFT_TOP_HALF:
			var left_wall = MeshInstance3D.new()
			left_wall.mesh = PlaneMesh.new()
			left_wall.mesh.set_size(HALF_SIZE)
			left_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			left_wall.position = TOP_WALL_OFFSET + position_offset + LEFT_HALF_OFFSET
			left_wall.rotation = HORIZONTAL_WALL_OFFSET
			left_wall.mesh.material = material
			self.add_child(left_wall)
			walls[segment].push_front(left_wall)
			print("\tCreating Left Top Half wall at: " + str(LEFT_WALL_OFFSET + position_offset + TOP_HALF_OFFSET))
		
		# Left Bottom Half
		if type == RIGHT_LEFT_BOTTOM_HALF or type == BOTTOM_RIGHT_LEFT_BOTTOM_HALF:
			var left_wall = MeshInstance3D.new()
			left_wall.mesh = PlaneMesh.new()
			left_wall.mesh.set_size(HALF_SIZE)
			left_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			left_wall.position = LEFT_WALL_OFFSET + position_offset + BOTTOM_HALF_OFFSET
			left_wall.rotation = VERTICAL_WALL_OFFSET
			left_wall.mesh.material = material
			self.add_child(left_wall)
			walls[segment].push_front(left_wall)
			print("\tCreating Left Bottom Half wall at: " + str(LEFT_WALL_OFFSET + position_offset + BOTTOM_HALF_OFFSET))
		
		# Bottom Left Half
		if type == TOP_BOTTOM_LEFT_HALF or type == TOP_LEFT_BOTTOM_LEFT_HALF:
			var bottom_wall = MeshInstance3D.new()
			bottom_wall.mesh = PlaneMesh.new()
			bottom_wall.mesh.set_size(HALF_SIZE)
			bottom_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			bottom_wall.position = BOTTOM_WALL_OFFSET + position_offset + LEFT_HALF_OFFSET
			bottom_wall.rotation = HORIZONTAL_WALL_OFFSET
			bottom_wall.mesh.material = material
			self.add_child(bottom_wall)
			walls[segment].push_front(bottom_wall)
			print("\tCreating Bottom Left Half wall at: " + str(BOTTOM_WALL_OFFSET + position_offset + LEFT_HALF_OFFSET))
		
		# Bottom Right Half
		if type == TOP_BOTTOM_RIGHT_HALF or type == TOP_RIGHT_BOTTOM_RIGHT_HALF:
			var bottom_wall = MeshInstance3D.new()
			bottom_wall.mesh = PlaneMesh.new()
			bottom_wall.mesh.set_size(HALF_SIZE)
			bottom_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			bottom_wall.position = BOTTOM_WALL_OFFSET + position_offset + RIGHT_HALF_OFFSET
			bottom_wall.rotation = HORIZONTAL_WALL_OFFSET
			bottom_wall.mesh.material = material
			self.add_child(bottom_wall)
			walls[segment].push_front(bottom_wall)
			print("\tCreating Bottom Right Half wall at: " + str(BOTTOM_WALL_OFFSET + position_offset + RIGHT_HALF_OFFSET))
			
		# Right Top Half
		if type == LEFT_RIGHT_TOP_HALF or type == TOP_LEFT_RIGHT_TOP_HALF:
			var right_wall = MeshInstance3D.new()
			right_wall.mesh = PlaneMesh.new()
			right_wall.mesh.set_size(HALF_SIZE)
			right_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			right_wall.position = RIGHT_WALL_OFFSET + position_offset + TOP_HALF_OFFSET
			right_wall.rotation = VERTICAL_WALL_OFFSET
			right_wall.mesh.material = material
			self.add_child(right_wall)
			walls[segment].push_front(right_wall)
			print("\tCreating Right Top Half wall at: " + str(RIGHT_WALL_OFFSET + position_offset + TOP_HALF_OFFSET))
		
		# Right Bottom Half
		if type == LEFT_RIGHT_BOTTOM_HALF or type == BOTTOM_LEFT_RIGHT_BOTTOM_HALF:
			var right_wall = MeshInstance3D.new()
			right_wall.mesh = PlaneMesh.new()
			right_wall.mesh.set_size(HALF_SIZE)
			right_wall.mesh.set_orientation(PlaneMesh.FACE_Z)
			right_wall.position = RIGHT_WALL_OFFSET + position_offset + BOTTOM_HALF_OFFSET
			right_wall.rotation = VERTICAL_WALL_OFFSET
			right_wall.mesh.material = material
			self.add_child(right_wall)
			walls[segment].push_front(right_wall)
			print("\tCreating Right Bottom Half wall at: " + str(RIGHT_WALL_OFFSET + position_offset + BOTTOM_HALF_OFFSET))

# hide walls depending on which  hallway segment user is currently in
#func hide_all_but_door1():
	#for segment in walls:
		#if segment != DOOR1:
			#for wall in segment:
				#wall.hide()
#
#func hide_all_but_threshold1():
	#
#
#func hide_all_but_middle_bit():
	#for segment in walls:
		#if segment != MIDDLE_BIT:
			#for wall in segment:
				#wall.hide()
#
#func hide_all_but_threshold2():
	#for segment in walls:
		#if segment != THRESHOLD2:
			#for wall in segment:
				#wall.hide()
#
#func hide_all_but_door2():
	#for segment in walls:
		#if segment != DOOR2:
			#for wall in segment:
				#wall.hide()		

# transition functions between hallway segments
func _on_entered_hallway(start_door, end_door): # door1
	draw_path(start_door, end_door)
	hide_all_but_door1()

func hide_all_but_door1():
	for i in range(walls.size()):
		if i != DOOR1:
			for wall in walls[i]:
				wall.hide()

func door1_to_threshold1():
	for i in range(walls.size()):
		if i == THRESHOLD1:
			for wall in walls[i]:
				wall.show()

func threshold1_to_middle_bit():
	for i in range(walls.size()):
		if i == MIDDLE_BIT or i == THRESHOLD2 or i == DOOR2:
			for wall in walls[i]:
				wall.show()
				
func middle_bit_to_threshold2():
	for i in range(walls.size()):
		if i == THRESHOLD1 or i == MIDDLE_BIT or i == DOOR1:
			for wall in walls[i]:
				wall.hide()

func threshold2_to_door2():
	for i in range(walls.size()):
		if i == THRESHOLD2:
			for wall in walls[i]:
				wall.hide()

func threshold1_to_door1():
	for i in range(walls.size()):
		if i == THRESHOLD1:
			for wall in walls[i]:
				wall.hide()

func middle_bit_to_threshold1():
	for i in range(walls.size()):
		if i == THRESHOLD2 or i == DOOR2 or i == MIDDLE_BIT:
			for wall in walls[i]:
				wall.hide()

func threshold2_to_middle_bit():
	for i in range(walls.size()):
		if i == THRESHOLD1 or i == DOOR1 or i == MIDDLE_BIT:
			for wall in walls[i]:
				wall.show()

func door2_to_threshold2():
	for i in range(walls.size()):
		if i == THRESHOLD2:
			for wall in walls[i]:
				wall.show()

func _on_exited_hallway(): # door2
	for segment in walls:
		for wall in segment:
			self.remove_child(wall)
			print(self.get_child_count())
	walls = [[], [], [], [], []]

func _on_hallway_transition(index):
	if index == 0:
		door1_to_threshold1()
	elif index == 1:
		threshold1_to_middle_bit()
	elif index == 2:
		middle_bit_to_threshold2()
	elif index == 3:
		threshold2_to_door2()
	elif index == 4:
		threshold1_to_door1()
	elif index == 5:
		middle_bit_to_threshold1()
	elif index == 6:
		threshold2_to_middle_bit()
	elif index == 7:
		door2_to_threshold2()
