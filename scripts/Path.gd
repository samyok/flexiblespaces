extends Node3D


func _process(_delta):
	pass


enum Direction { UP = 0, DOWN = 2, LEFT = 3, RIGHT = 1 }


class RightAngledPath:
	var points: Array[Vector2] = []
	var left_side: Array[Vector2] = []
	var right_side: Array[Vector2] = []
	var width: float = 2.0
	const HORIZONTAL_DIRECTIONS = [Direction.LEFT, Direction.RIGHT]
	const VERTICAL_DIRECTIONS = [Direction.UP, Direction.DOWN]
	const DIRECTIONS = {
		Direction.UP: Vector2(0, 1),
		Direction.DOWN: Vector2(0, -1),
		Direction.LEFT: Vector2(-1, 0),
		Direction.RIGHT: Vector2(1, 0)
	}

	const LEFT_CONNECTORS = {  # going from [d1] to [d2], where is the left wall corner point relative to the center of the path?
		Direction.RIGHT:
		{
			Direction.UP: Vector2(-1, 1),
			Direction.DOWN: Vector2(1, 1),
		},
		Direction.LEFT:
		{
			Direction.UP: Vector2(-1, -1),
			Direction.DOWN: Vector2(1, -1),
		},
		Direction.UP:
		{
			Direction.LEFT: Vector2(-1, -1),
			Direction.RIGHT: Vector2(-1, 1),
		},
		Direction.DOWN:
		{
			Direction.LEFT: Vector2(1, -1),
			Direction.RIGHT: Vector2(1, 1),
		},
	}

	func transpose(v: Vector2) -> Vector2:
		return Vector2(v.y, v.x)

	func find_direction(point: Vector2, next_point: Vector2) -> Direction:
		if point.x == next_point.x:
			if point.y < next_point.y:
				return Direction.UP
			else:
				return Direction.DOWN
		else:
			if point.x < next_point.x:
				return Direction.RIGHT
			else:
				return Direction.LEFT

	func left_side_endpoint(point: Vector2, direction: Direction) -> Vector2:
		var delta = width / 2
		if direction == Direction.UP:
			return point + delta * Vector2(-1, 0)
		elif direction == Direction.DOWN:
			return point + delta * Vector2(1, 0)
		elif direction == Direction.LEFT:
			return point + delta * Vector2(0, -1)
		elif direction == Direction.RIGHT:
			return point + delta * Vector2(0, 1)
		else:
			print("ERROR: unknown direction ", direction)
			return Vector2(0, 0)

	func compute_path():
		left_side.clear()
		right_side.clear()
		# first point is easy
		var delta = width / 2
		var n = points.size()

		var first_dir = find_direction(points[0], points[1])

		left_side.append(left_side_endpoint(points[0], first_dir))

		for i in range(1, n - 1):
			var prev_direction = find_direction(points[i - 1], points[i])
			print("prev direction from ", points[i - 1], " to ", points[i], " is ", prev_direction)
			var next_direction = find_direction(points[i], points[i + 1])
			# create all the connectors for the left side
			print("prev: ", prev_direction, " next: ", next_direction)
			var left_connector = LEFT_CONNECTORS[prev_direction][next_direction]
			print("using connector ", left_connector)
			var left_point = points[i] + delta * left_connector
			left_side.append(left_point)

		var last_dir = find_direction(points[n - 2], points[n - 1])
		left_side.append(left_side_endpoint(points[n - 1], last_dir))

		for i in range(n):
			# x - (x - left) = 2x - left
			right_side.append(2 * points[i] - left_side[i])


func draw_path(p: RightAngledPath):
	var n = p.left_side.size()
	for i in range(n - 1):
		create_wall(p.left_side[i], p.left_side[i + 1])
		create_wall(p.right_side[i], p.right_side[i + 1])


# Called when the node enters the scene tree for the first time.
func _ready():
	# var path: RightAngledPath = RightAngledPath.new()

	# path.points = [Vector2(1, 1), Vector2(1, 4)]
	# path.compute_path()
	# print("left: ", path.left_side)  # should be [(0, 1), (0, 4)]
	# print("right: ", path.right_side)  # should be [(2, 1), (2, 4)]

	# path.points = [Vector2(1, 1), Vector2(1, 4), Vector2(4, 4)]
	# path.compute_path()
	# print("left: ", path.left_side)  # should be [(0, 1), (0, 5), (4, 5)]
	# print("right: ", path.right_side)  # should be [(2, 1), (2, 4), (5, 4)]

	# path.points = [Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	# path.width = 0.5
	# path.compute_path()
	# print("points: ", path.points)
	# print("left: ", path.left_side)
	# print("right: ", path.right_side)

	# # create_wall(Vector2(0, 0), Vector2(5, 0))
	# # create_wall(Vector2(5, 0), Vector2(5, 5))

	# path.points = [Vector2(0, 0), Vector2(5, 0), Vector2(5, 5)]
	# path.width = 3.0
	# path.compute_path()
	# draw_path(path)
	generate_flexible_spaces_points(Vector2(0, 0), Vector2(2, -8))


# given two points, we have to create a wall between them
func create_wall(point1: Vector2, point2: Vector2):
	var template = get_node("%wall_template")
	var new_wall = template.duplicate()
	new_wall.position.x = (point1.x + point2.x) / 2
	new_wall.position.y = 0  # TODO: remove [debugging walls]
	new_wall.position.z = (point1.y + point2.y) / 2
	# var length = direction.length()
	if point1.x == point2.x:
		new_wall.rotation_degrees = Vector3(0, 90, 0)

	new_wall.scale.x = point1.distance_to(point2)
	# new_wall.look_at(Vector3(direction.x, 0, direction.y), Vector3(0, 1, 0))
	add_child(new_wall)
	new_wall.visible = true


# @export var BOUNDS = {"x": [-10, 10], "z": [-10, 10]}


func generate_flexible_spaces_points(start: Vector2, end: Vector2):
	# randomly generate an I in the bounds
	var x = randf_range(-10, 10)
	var z = randf_range(-10, 10)

	var i = Vector2(x, z)
	# TODO: test if I is in room 1, room 2, or "behind room 1" -- just not trivially breaking the illusion

	# now turn start -> i -> end into a right-angled path
	var path: RightAngledPath = RightAngledPath.new()

	var si = Vector2(i.x, start.y)
	var ie = Vector2(end.x, i.y)

	path.points = [start, si, i, ie, end]
	path.width = 1
	path.compute_path()
	draw_path(path)
	return path
