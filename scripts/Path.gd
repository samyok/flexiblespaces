extends Node3D

const FLEXIBLE_ROOM_SIDE_LENGTH = 10
const TRACKABLE_AREA_BOUNDS = [Vector2(0, 0), Vector2(10, 10)]  # mins  # maxs
const ROOM_WIDTH = 4


func _process(_delta):
	pass


# func create_most_open_door(room: FlexibleRoom) -> Vector2:
# 	# check all four directions to see which has the most open space
# 	var north = TRACKABLE_AREA_BOUNDS[1].y - room.bounds()[1].y
# 	var south = room.bounds()[0].y - TRACKABLE_AREA_BOUNDS[0].y
# 	var east = TRACKABLE_AREA_BOUNDS[1].x - room.bounds()[1].x
# 	var west = room.bounds()[0].x - TRACKABLE_AREA_BOUNDS[0].x

# 	var direction = Vector2(0, 0)
# 	var max_open = max(north, south, east, west)
# 	if max_open == north:
# 		direction = Vector2(0, 1)
# 	elif max_open == south:
# 		direction = Vector2(0, -1)
# 	elif max_open == east:
# 		direction = Vector2(1, 0)
# 	elif max_open == west:
# 		direction = Vector2(-1, 0)

# 	return room.create_door(direction + room.position)


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
	# create room at [2, 2]
	# var c1 = Vector2(2, 8)
	# var r1 = FlexibleRoom.new(self.get_parent(), c1)
	# put a door on the side
	# var d1 = r1.create_door(Vector2(2, 6))

	# create another room at [5, 4]
	# var c2 = Vector2(5, 4)
	# var r2 = FlexibleRoom.new(self.get_parent(), c2)
	# put a door on the side facing the most open space in the trackable area
	# var d2 = create_most_open_door(r2)

	# var points = generate_flexible_bfs_points(r1, r2)

	# var starting_point = find_point_outside_door(r1)

	# var ending_point = find_point_outside_door(r2)

	# var path = generate_flexible_bfs_points(r1, r2)

	# print("creating path from points: ", path)
	# var rapath = RightAngledPath.new()
	# rapath.points = path

	# generate the path for walls
	# rapath.compute_path()

	# print("rendering rooms")
	# render the rooms
	# room_walls(r1)
	# room_walls(r2)

	# render the path
	# draw_path(rapath)

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
	new_wall.position.y = 1  # TODO: remove [debugging walls]
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


static func is_point_in_room(point: Vector2, room: FlexibleRoom) -> bool:
	var mins = room.bounds()[0]
	var maxs = room.bounds()[1]

	return point.x >= mins.x and point.x <= maxs.x and point.y >= mins.y and point.y <= maxs.y


func is_valid_point(x, z):
	# check if x or z is in any of the rooms
	for room in rooms:
		if room.is_point_inside(Vector2(x, z)):
			return false

	return true


# static func find_point_outside_door(room: FlexibleRoom):
# 	# get door position
# 	var door = room.door_point
# 	# add a point 1m in each direction orthogonal to the wall the door is on
# 	var direction = room.door_direction
# 	var pointA = door + direction.orthogonal() * 1
# 	var pointB = door + direction.orthogonal() * -1

# 	if not room.is_point_inside(pointA):
# 		return pointA
# 	return point


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

	if room.is_point_inside(pointA):
		return pointB

	return pointA


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

	var path: RightAngledPath = RightAngledPath.new([])

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
