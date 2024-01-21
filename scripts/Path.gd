extends Node3D

const FLEXIBLE_ROOM_SIDE_LENGTH = 10
const TRACKABLE_AREA_BOUNDS = [Vector2(0, 0), Vector2(10, 10)]  # mins  # maxs
const ROOM_WIDTH = 4
var paths
var current_path

func _ready():
	paths = [self.find_child("Path1"), self.find_child("Path2"), self.find_child("Path3"), self.find_child("Path4"), self.find_child("Path5"), self.find_child("Path6"), self.find_child("Path7"), self.find_child("Path8"), self.find_child("Path9"), self.find_child("Path10"), self.find_child("Path11"), self.find_child("Path12")]

func draw_path(start_door, end_door):
	var rand = randi_range(0, 3)
	# North
	if start_door == 0:
		# Rotate
		self.rotation.y = 0
		# Right
		if end_door == 1:
			if rand == 0:
				current_path = paths[0]
			elif rand == 1:
				current_path = paths[1]
			elif rand == 2:
				current_path = paths[2]
			else:
				current_path = paths[3]
		# Straight
		elif end_door == 2:
			if rand == 0:
				current_path = paths[4]
			elif rand == 1:
				current_path = paths[5]
			elif rand == 2:
				current_path = paths[6]
			else:
				current_path = paths[7]
		# Left
		else: # end_door == 3
			if rand == 0:
				current_path = paths[8]
			elif rand == 1:
				current_path = paths[9]
			elif rand == 2:
				current_path = paths[10]
			else:
				current_path = paths[12]
		current_path.show()

	# East
	elif start_door == 1:
		# Rotate
		self.rotation.y = -PI/2
		# Right
		if end_door == 2:
			if rand == 0:
				current_path = paths[0]
			elif rand == 1:
				current_path = paths[1]
			elif rand == 2:
				current_path = paths[2]
			else:
				current_path = paths[3]
		# Straight
		elif end_door == 3:
			if rand == 0:
				current_path = paths[4]
			elif rand == 1:
				current_path = paths[5]
			elif rand == 2:
				current_path = paths[6]
			else:
				current_path = paths[7]
		# Left
		else: # end_door == 0
			if rand == 0:
				current_path = paths[8]
			elif rand == 1:
				current_path = paths[9]
			elif rand == 2:
				current_path = paths[10]
			else:
				current_path = paths[12]
		current_path.show()

	# South
	elif start_door == 2:
		# Rotate
		self.rotation.y = PI
		# Right
		if end_door == 3:
			if rand == 0:
				current_path = paths[0]
			elif rand == 1:
				current_path = paths[1]
			elif rand == 2:
				current_path = paths[2]
			else:
				current_path = paths[3]
		# Straight
		elif end_door == 0:
			if rand == 0:
				current_path = paths[4]
			elif rand == 1:
				current_path = paths[5]
			elif rand == 2:
				current_path = paths[6]
			else:
				current_path = paths[7]
		# Left
		else: # end_door == 1
			if rand == 0:
				current_path = paths[8]
			elif rand == 1:
				current_path = paths[9]
			elif rand == 2:
				current_path = paths[10]
			else:
				current_path = paths[12]
		current_path.show()

	# West
	else:
		# Rotate
		self.rotation.y = PI/2
		# Right
		if end_door == 0:
			if rand == 0:
				current_path = paths[0]
			elif rand == 1:
				current_path = paths[1]
			elif rand == 2:
				current_path = paths[2]
			else:
				current_path = paths[3]
		# Straight
		elif end_door == 1:
			if rand == 0:
				current_path = paths[4]
			elif rand == 1:
				current_path = paths[5]
			elif rand == 2:
				current_path = paths[6]
			else:
				current_path = paths[7]
		# Left
		else: # end_door == 2
			if rand == 0:
				current_path = paths[8]
			elif rand == 1:
				current_path = paths[9]
			elif rand == 2:
				current_path = paths[10]
			else:
				current_path = paths[12]
		current_path.show()


func _on_entered_hallway(start_door, end_door):
	draw_path(start_door, end_door)

func _on_exited_hallway():
	current_path.hide()
