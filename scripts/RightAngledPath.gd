extends Object
class_name RightAngledPath

enum Direction { UP = 0, DOWN = 2, LEFT = 3, RIGHT = 1 }

var points: Array[Vector2] = []

# points that belong to the left hand side wall
var left_side: Array[Vector2] = []
var right_side: Array[Vector2] = []
var width: float = 1.0
var wall_nodes: Array[Node3D] = []

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


func _init(_points: Array[Vector2]):
	# create a path between two rooms
	points = _points

# util function to transpose a vector (couldn't find something builtin)
func transpose(v: Vector2) -> Vector2:
	return Vector2(v.y, v.x)

# figure out what direction a->b is going -- useful for figuring out which
# wall is the LHS
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

# find the correct LHS wall point
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


# compute the length of the path (sum of the lengths of the segments)
func length() -> float:
	var n = points.size()
	var total = 0
	for i in range(n - 1):
		total += points[i].distance_to(points[i + 1])

	return total


# if a -> b -> c are on the same line, remove b
func remove_redundant_points():
	var n = points.size()
	var i = 0
	while i < n - 2:
		var a = points[i]
		var b = points[i + 1]
		var c = points[i + 2]

		var ab = b - a
		var bc = c - b

		if ab.normalized() == bc.normalized():
			points.pop_at(i + 1)
			n -= 1
		else:
			i += 1

# compute the wall points needed for a certain path
func compute_path():
	left_side.clear()
	right_side.clear()

	remove_redundant_points()
	print("cleaned up points: ", points)

	# first point is easy
	var delta = width / 2
	var n = points.size()

	var first_dir = find_direction(points[0], points[1])

	left_side.append(left_side_endpoint(points[0], first_dir))

	for i in range(1, n - 1):
		var prev_direction = find_direction(points[i - 1], points[i])
		print("prev direction from ", points[i - 1], " to ", points[i], " is ", prev_direction)

		var next_direction = find_direction(points[i], points[i + 1])
		print("next direction from ", points[i], " to ", points[i + 1], " is ", next_direction)

		# create all the connectors for the left side
		var left_connector = LEFT_CONNECTORS[prev_direction][next_direction]
		print("using connector ", left_connector)

		var left_point = points[i] + delta * left_connector
		left_side.append(left_point)

	var last_dir = find_direction(points[n - 2], points[n - 1])
	left_side.append(left_side_endpoint(points[n - 1], last_dir))

	for i in range(n):
		# x - (x - left) = 2x - left
		right_side.append(2 * points[i] - left_side[i])


# custom sort by length of paths
static func lensort(a: RightAngledPath, b: RightAngledPath) -> float:
	return a.length() - b.length()

# generate a set of points found by bfs-ing, from one room to another. 
# it starts/ends from the points outside the doors to allow for path walls to
# not break the immersiveness 
static func generate_flexible_bfs_points(start: FlexibleRoom, end: FlexibleRoom) -> Array[Vector2]:
	var queue = []

	var startpoint = start.point_outside_door()
	var startpath: Array[Vector2] = [startpoint]
	queue.append({"point": startpoint, "path": startpath})
	var endpoint = end.point_outside_door()

	var prefix: Array[Vector2] = [start.door_point]
	var suffix: Array[Vector2] = [end.door_point]

	var point_behind_start_door = start.door_point - (start.door_point - startpoint).normalized()
	var point_behind_end_door = end.door_point - (end.door_point - endpoint).normalized()
	var not_allowed_points = [point_behind_start_door, point_behind_end_door]

	# make sure that the first three points are not inside the
	# in addition, make sure that only valid moves are being made. ie, don't do
	# the opposite of the last move.

	while queue.size() > 0:
		var current = queue.pop_front()
		var point = current["point"]
		var path: Array[Vector2] = current["path"]

		if point == endpoint:
			# don't let the last three points be in the end room
			print("checking path ", path)
			var last_three: Array[Vector2] = []
			for i in range(max(0, path.size() - 3), path.size()):
				last_three.append(path[i])

			if end.is_any_point_inside(last_three):
				continue
			return prefix + path + suffix

		var directions = [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]
		# so that each path is somewhat random but is still the shortest valid path
		directions.shuffle()

		for direction in directions:
			# check if the direction is opposite of the last direction
			if path.size() > 1:
				var last_direction = path[path.size() - 1] - path[path.size() - 2]
				if last_direction == -direction:
					continue

			var new_point = point + direction

			# don't repeat points
			if path.has(new_point) or prefix.has(new_point) or suffix.has(new_point):
				continue

			# don't let the first three points be in the inital room
			if path.size() <= 3:
				if start.is_point_inside(new_point):
					continue

			# don't let points exist right behind the door
			# if not_allowed_points.has(new_point):
			# continue

			var new_path = path.duplicate()
			new_path.append(new_point)
			queue.append({"point": new_point, "path": new_path})

	return []
