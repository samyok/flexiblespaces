extends Node3D

const start_pos = Vector2(2, 8)


func _on_xr_user_area_entered(area: Area3D):
	print("user entered ", area)
	var door_num = get_room_from_door(area)
	if door_num == -1:
		print("door not found")
		return

	if State.location == State.LOCATION.ROOM:
		print("entering path from room ", door_num)
		State.location = State.LOCATION.PATH

		# remove the current room from the scene
		hide_room(State.rooms[State.current_room])

		# increment the current room
		State.current_room = door_num + 1

		if State.current_room >= State.rooms.size():
			# todo: create more rooms
			print("no more rooms, creating one")
			create_room()

		# render the path we're entering
		render_path(State.paths[State.current_room])

		# render the door we're entering
		render_door(State.rooms[State.current_room])

	elif State.location == State.LOCATION.PATH:
		print("entering room from path ", door_num)
		State.location = State.LOCATION.ROOM
		State.current_room = door_num

		# remove all the paths from the scene
		for path in State.paths:
			hide_path(path)
		# if State.paths[State.current_room] != null:
		# 	hide_path(State.paths[State.current_room])

		# remove all other doors from the scene
		for i in range(State.rooms.size()):
			if i != State.current_room:
				hide_door(State.rooms[i])

		# render the room we're entering
		render_room(State.rooms[State.current_room])


func _on_xr_user_area_exited(area: Area3D):
	print("user exited ", area)


func _physics_process(delta):
	if State.current_room == null:
		return

	# var camera = get_node("%XRCamera3D")
	# var user = get_node("%XRUser")
	# if State.location == State.LOCATION.ROOM:
	# 	var current_room = State.rooms[State.current_room]
	# 	var current_door = current_room.door
	# 	# print("current door: ", current_door)
	# 	# print("user: ", user)
	# 	# print("user overlaps door: ", current_door.overlaps_area(user))
	# 	if current_door.overlaps_area(user):
	# 		State.location = State.LOCATION.PORTAL
	# 		print(" >> PORTAL ENTERED << ")


# func process_room(camera):
# 	# we're currently in a room, check if we're in the portal


func _ready():
	# create a room at 2, 8 (where the user is initially)
	State.add_room(FlexibleRoom.new(get_parent(), start_pos))

	# hard-coded door for start
	State.rooms[0].create_door(Vector2(2, 6))

	# create another room at 5, 4 just to test for now
	State.add_room(FlexibleRoom.new(get_parent(), Vector2(5, 4)))
	State.rooms[1].create_most_open_door()

	var points: Array[Vector2] = RightAngledPath.generate_flexible_bfs_points(
		State.rooms[0], State.rooms[1]
	)

	print("bfs points, ", points)
	var path = RightAngledPath.new(points)

	path.compute_path()
	print("computed ", path.points)

	State.paths.append(path)
	render_room(State.rooms[0])
	render_door(State.rooms[0])
	# render_room(State.rooms[1])
	# render_path(path)


# helpers


func create_room():
	# create a room in a random lattice point within the bounds of TRACKABLE_AREA_BOUNDS
	var TAG = State.TRACKABLE_AREA_BOUNDS
	var no_go_zone := int(State.ROOM_SIZE / 2.0)

	var x = randi_range(TAG[0].x + no_go_zone, TAG[1].x - no_go_zone + 1)
	var y = randi_range(TAG[0].y + no_go_zone, TAG[1].y - no_go_zone + 1)

	print("-> creating room at ", x, ", ", y)

	var room = FlexibleRoom.new(get_parent(), Vector2(x, y))
	room.create_most_open_door()

	var points: Array[Vector2] = RightAngledPath.generate_flexible_bfs_points(
		State.rooms.back(), room
	)

	print("-> bfs found: ", points)
	var path = RightAngledPath.new(points)

	path.compute_path()
	print("-> after clean: ", path.points)

	State.add_room(room)
	State.paths.append(path)


# given an area (door), return the room it belongs to, or -1 if it doesn't belong to any room
func get_room_from_door(door: Area3D) -> int:
	for i in range(State.rooms.size()):
		if State.rooms[i].door == door:
			return i
	return -1


# given two points, we have to create a wall between them
func render_wall(point1: Vector2, point2: Vector2) -> CSGMesh3D:
	var template = get_node("%wall_template")
	var new_wall = template.duplicate()
	new_wall.position.x = (point1.x + point2.x) / 2
	# UNCOMMENT THIS LINE TO SHOW ALL THE WALLS
	# new_wall.position.y = 0  # TODO: remove [debugging walls]
	new_wall.position.z = (point1.y + point2.y) / 2
	# var length = direction.length()
	if point1.x == point2.x:
		new_wall.rotation_degrees = Vector3(0, 90, 0)

	new_wall.scale.x = point1.distance_to(point2)
	# new_wall.look_at(Vector3(direction.x, 0, direction.y), Vector3(0, 1, 0))
	add_child(new_wall)
	new_wall.visible = true
	return new_wall


# only render doors if they don't already exist
func render_door(room) -> Area3D:
	if room.door != null:
		return

	var center = room.door_point
	var direction = room.door_direction

	var template = get_node("%door_template")
	var new_door = template.duplicate()

	new_door.position.x = center.x
	new_door.position.y = 0
	new_door.position.z = center.y

	if direction.x == 0:
		new_door.rotation_degrees = Vector3(0, 90, 0)

	new_door.scale.x = 1

	add_child(new_door)

	new_door.visible = true

	room.door = new_door
	return new_door


func hide_door(room: FlexibleRoom):
	if room.door != null:
		room.door.queue_free()
		room.door = null


func hide_room(room: FlexibleRoom):
	for wall in room.wall_nodes:
		wall.queue_free()

	room.wall_nodes.clear()


func hide_path(path: RightAngledPath):
	if path == null:
		return
	for wall in path.wall_nodes:
		wall.queue_free()

	path.wall_nodes.clear()


# render a whole room with walls and doors and stuff.
func render_room(room: FlexibleRoom):
	for wall in room.wall_nodes:
		wall.queue_free()

	room.wall_nodes.clear()

	for wall in room.walls:
		room.wall_nodes.append(render_wall(wall[0], wall[1]))

	# if room.door != null:
	# 	room.door.queue_free()

	# render_door(room)


# render the walls of a right angled path
func render_path(p: RightAngledPath):
	hide_path(p)
	p.wall_nodes.clear()
	var n = p.left_side.size()
	for i in range(n - 1):
		p.wall_nodes.append(render_wall(p.left_side[i], p.left_side[i + 1]))
		p.wall_nodes.append(render_wall(p.right_side[i], p.right_side[i + 1]))
