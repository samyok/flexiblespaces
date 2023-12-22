extends Node3D

const FLEXIBLE_ROOM_SIDE_LENGTH = 10
const TRACKABLE_AREA_BOUNDS = [Vector2(0, 0), Vector2(10, 10)]  # mins  # maxs
const ROOM_WIDTH = 4

const FlexibleRoom = preload("FlexibleRoom.gd")


func _process(_delta):
	pass


func create_most_open_door(room: FlexibleRoom) -> Vector2:
	# check all four directions to see which has the most open space
	var north = TRACKABLE_AREA_BOUNDS[1].y - room.bounds()[1].y
	var south = room.bounds()[0].y - TRACKABLE_AREA_BOUNDS[0].y
	var east = TRACKABLE_AREA_BOUNDS[1].x - room.bounds()[1].x
	var west = room.bounds()[0].x - TRACKABLE_AREA_BOUNDS[0].x

	var direction = Vector2(0, 0)
	var max_open = max(north, south, east, west)
	if max_open == north:
		direction = Vector2(0, 1)
	elif max_open == south:
		direction = Vector2(0, -1)
	elif max_open == east:
		direction = Vector2(1, 0)
	elif max_open == west:
		direction = Vector2(-1, 0)

	return room.create_door(direction + room.position)


func is_any_point_in_room(points: Array, room: FlexibleRoom) -> bool:
	for point in points:
		if is_point_in_room(point, room):
			return true

	return false


func generate_flexible_bfs_points(start: FlexibleRoom, end: FlexibleRoom) -> Array[Vector2]:
	var queue = []

	var startpoint = find_point_outside_door(start)
	var startpath: Array[Vector2] = [startpoint]
	queue.append({"point": startpoint, "path": startpath})
	var endpoint = find_point_outside_door(end)

	var prefix: Array[Vector2] = [start.door_point]
	var suffix: Array[Vector2] = [end.door_point]

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
			var last_three = []
			for i in range(max(0, path.size() - 3), path.size()):
				last_three.append(path[i])

			if is_any_point_in_room(last_three, end):
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

			# don't let the first three points be in the inital room
			var new_point = point + direction
			if path.size() <= 3:
				if is_point_in_room(new_point, start):
					continue

			var new_path = path.duplicate()
			new_path.append(new_point)
			queue.append({"point": new_point, "path": new_path})

	return []


# Called when the node enters the scene tree for the first time.
func _ready():
	# create room at [2, 2]
	var c1 = Vector2(2, 8)
	var r1 = FlexibleRoom.new(self.get_parent(), c1)
	# put a door on the side
	var d1 = r1.create_door(Vector2(2, 6))

	# create another room at [5, 4]
	var c2 = Vector2(5, 4)
	var r2 = FlexibleRoom.new(self.get_parent(), c2)
	# put a door on the side facing the most open space in the trackable area
	var d2 = create_most_open_door(r2)

	# var points = generate_flexible_bfs_points(r1, r2)

	# var starting_point = find_point_outside_door(r1)

	# var ending_point = find_point_outside_door(r2)

	var path = generate_flexible_bfs_points(r1, r2)

	print("creating path from points: ", path)
	var rapath = RightAngledPath.new()
	rapath.points = path

	# generate the path for walls
	rapath.compute_path()

	print("rendering rooms")
	# render the rooms
	# room_walls(r1)
	# room_walls(r2)

	# render the path
	draw_path(rapath)

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

	# create a room in the current location
	# var r1 = FlexibleRoom.new(self.get_parent(), Vector2(0, 0))
	# var _d1 = r1.create_door(Vector2(0, -1))
	# room_walls(r1)
	# active_rooms.append(r1)

	# var r2 = FlexibleRoom.new(self.get_parent(), Vector2(10, 10))
	# print(r2.walls)
	# # var _d2 = r2.create_door(Vector2(0, -1))
	# room_walls(r2)
	# active_rooms.append(r2)

	# generate_flexible_spaces_points(r1, r2)

	# then, when the room
	# generate_flexible_spaces_points(Vector2(0, 0), Vector2(2, -8))


enum Direction { UP = 0, DOWN = 2, LEFT = 3, RIGHT = 1 }


class RightAngledPath:
	var points: Array[Vector2] = []
	var left_side: Array[Vector2] = []
	var right_side: Array[Vector2] = []
	var width: float = 1.0
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

	func length() -> float:
		# compute the length of the path (sum of the lengths of the segments)
		var n = points.size()
		var total = 0
		for i in range(n - 1):
			total += points[i].distance_to(points[i + 1])

		return total

	func remove_redundant_points():
		# if a -> b -> c are on the same line, remove b
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

	static func lensort(a: RightAngledPath, b: RightAngledPath) -> float:
		return a.length() - b.length()


func draw_path(p: RightAngledPath):
	var n = p.left_side.size()
	for i in range(n - 1):
		create_wall(p.left_side[i], p.left_side[i + 1])
		create_wall(p.right_side[i], p.right_side[i + 1])


var rooms = []  # holds _all_ the rooms
var active_rooms = []


func room_walls(room: FlexibleRoom):
	for wall in room.wall_nodes:
		wall.erase()

	room.wall_nodes.clear()

	for wall in room.walls:
		create_wall(wall[0], wall[1])


# given two points, we have to create a wall between them
func create_wall(point1: Vector2, point2: Vector2) -> CSGMesh3D:
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
	return new_wall


# @export var BOUNDS = {"x": [-10, 10], "z": [-10, 10]}


func is_point_in_room(point: Vector2, room: FlexibleRoom) -> bool:
	var mins = room.bounds()[0]
	var maxs = room.bounds()[1]

	return point.x >= mins.x and point.x <= maxs.x and point.y >= mins.y and point.y <= maxs.y


func is_valid_point(x, z):
	# check if x or z is in any of the rooms
	for room in rooms:
		if is_point_in_room(Vector2(x, z), room):
			return false

	return true


func find_point_outside_door(room):
	# get door position
	var door = room.door_point
	# add a point 1m in each direction orthogonal to the wall the door is on
	var direction = room.door_direction
	var pointA = door + direction.orthogonal() * 1
	var pointB = door + direction.orthogonal() * -1

	if not is_point_in_room(pointA, room):
		return pointA
	return pointB


func find_helper_i(room):
	# ensure that the room has a door
	if room.door_point == null:
		print("ERROR: room ", room, " has no door")
		return null

	# get door position
	var door = room.door_point
	# get door direction
	var direction = room.door_direction

	var pointA = door + direction.orthogonal() * 1
	var pointB = door + direction.orthogonal() * -1

	if is_point_in_room(pointA, room):
		return pointA

	return pointB


func generate_possible_path(start: FlexibleRoom, end: FlexibleRoom):
	# randomly generate an I in the bounds
	var x = 0
	var z = 0

	x = randf_range(-FLEXIBLE_ROOM_SIDE_LENGTH, FLEXIBLE_ROOM_SIDE_LENGTH)
	z = randf_range(-FLEXIBLE_ROOM_SIDE_LENGTH, FLEXIBLE_ROOM_SIDE_LENGTH)

	var i = Vector2(x, z)
	# TODO: test if I is in room 1, room 2, or "behind room 1" -- just not trivially breaking the illusion

	# create a helper_i that is on the orthogonal, making sure that it's not inside the room

	# now turn start -> i -> end into a right-angled path

	var path: RightAngledPath = RightAngledPath.new()

	var si = Vector2(i.x, start.y)
	var ie = Vector2(end.x, i.y)

	# path.points = [start, si, i, ie, end]
	path.width = 1
	path.compute_path()

	# draw_path(path)
	return path


func generate_flexible_spaces_points(start: FlexibleRoom, end: FlexibleRoom):
	var paths = []
	for i in range(10):
		var p = generate_possible_path(start, end)
		paths.append(p)
		print("path len: ", p.length(), " path ", p)

	paths.sort_custom(RightAngledPath.lensort)
	# var path = generate_possible_path(start, end)

	print("using path ", paths[0])

	draw_path(paths[0])
	return paths[0]
