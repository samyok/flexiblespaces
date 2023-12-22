extends Object

class_name FlexibleRoom

var position: Vector2
var size: float
var room: Node3D
var walls: Array
var wall_nodes: Array[Node3D]
var wall_template: CSGMesh3D
var parent: Node3D
var door: Node3D
var door_point: Vector2
var door_direction: Vector2

var door_size = 1


func _init(_parent: Node3D, _position: Vector2 = Vector2(0, 0), _size = 4) -> void:
	self.position = _position
	# create coordinates of the walls based on the size of the room, where the position is the center of the room
	self.size = _size
	self.walls = [
		[
			Vector2(position.x - size / 2, position.y - size / 2),
			Vector2(position.x + size / 2, position.y - size / 2)
		],
		[
			Vector2(position.x + size / 2, position.y - size / 2),
			Vector2(position.x + size / 2, position.y + size / 2)
		],
		[
			Vector2(position.x + size / 2, position.y + size / 2),
			Vector2(position.x - size / 2, position.y + size / 2)
		],
		[
			Vector2(position.x - size / 2, position.y + size / 2),
			Vector2(position.x - size / 2, position.y - size / 2)
		],
	]

	print(_parent)
	self.room = Node3D.new()
	self.parent = _parent
	self.parent.get_tree().current_scene.add_child(self.room)
	self.wall_template = _parent.get_node("%wall_template")
	self.room.position = Vector3(position.x, 0, position.y)

	print("FlexibleRoom created at " + str(position))

	print("closest wall to (0, 0): " + str(self.wall_segment_closest_to_a_point(Vector2(0, 0))))

	# self.create_door(Vector2(1, 0))


func distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var closest_point = closest_point_on_segment_to_point(point, segment_start, segment_end)
	return point.distance_to(closest_point)


func closest_point_on_segment_to_point(
	point: Vector2, segment_start: Vector2, segment_end: Vector2
) -> Vector2:
	var v = segment_end - segment_start
	var w = point - segment_start

	var c1 = w.dot(v)
	if c1 <= 0:
		return segment_start

	var c2 = v.dot(v)
	if c2 <= c1:
		return segment_end

	var b = c1 / c2
	var pb = segment_start + v * b
	return pb


func wall_segment_closest_to_a_point(point: Vector2) -> Array:
	var closest_segment = 0

	for i in range(1, self.walls.size()):
		var dist = self.distance_to_segment(point, self.walls[i][0], self.walls[i][1])
		var distance_to_closest_segment = self.distance_to_segment(
			point, self.walls[closest_segment][0], self.walls[closest_segment][1]
		)
		if dist < distance_to_closest_segment:
			closest_segment = i

	var closest_point = self.closest_point_on_segment_to_point(
		point, self.walls[closest_segment][0], self.walls[closest_segment][1]
	)

	# if the point is on an endpoint, offset it by 1/2 door size
	if closest_point == self.walls[closest_segment][0]:
		closest_point = (
			closest_point
			+ (
				(self.walls[closest_segment][1] - self.walls[closest_segment][0]).normalized()
				* door_size
				/ 2
			)
		)
	elif closest_point == self.walls[closest_segment][1]:
		closest_point = (
			closest_point
			- (
				(self.walls[closest_segment][1] - self.walls[closest_segment][0]).normalized()
				* door_size
				/ 2
			)
		)

	return [closest_segment, closest_point]


# func _create_wall(point1: Vector2, point2: Vector2):
# 	print("wall created at " + str(point1) + " -> " + str(point2))
# 	var template = self.wall_template
# 	print(template)

# 	var new_wall = template.duplicate()
# 	new_wall.position.x = (point1.x + point2.x) / 2
# 	new_wall.position.y = 0  # TODO: remove [debugging walls]
# 	new_wall.position.z = (point1.y + point2.y) / 2
# 	# var length = direction.length()
# 	if point1.x == point2.x:
# 		new_wall.rotation_degrees = Vector3(0, 90, 0)

# 	new_wall.scale.x = point1.distance_to(point2)
# 	# new_wall.look_at(Vector3(direction.x, 0, direction.y), Vector3(0, 1, 0))
# 	self.parent.add_child(new_wall)
# 	new_wall.visible = true


func bounds() -> Array[Vector2]:
	var mnx = INF
	var mny = INF
	var mxx = -INF
	var mxy = -INF

	for wall in self.walls:
		mnx = min(mnx, wall[0].x, wall[1].x)
		mny = min(mny, wall[0].y, wall[1].y)
		mxx = max(mxx, wall[0].x, wall[1].x)
		mxy = max(mxy, wall[0].y, wall[1].y)

	return [Vector2(mnx, mny), Vector2(mxx, mxy)]


func create_door(point) -> Vector2:
	# creates a hole in the wall closest to a point
	var wall_seg = self.wall_segment_closest_to_a_point(point)
	var wall_idx = wall_seg[0]
	var wall_point = wall_seg[1]

	var wall = self.walls[wall_idx]
	var wall_start = wall[0]
	var wall_end = wall[1]

	# keep track of the wall_direction for the door
	self.door_direction = (wall_end - wall_start).normalized()

	# remove the wall from the list
	self.walls.pop_at(wall_idx)

	# add a new wall from start to wall_point - door_size / 2
	self.walls.append(
		[wall_start, wall_point - (wall_point - wall_start).normalized() * door_size / 2]
	)

	# add a new wall from wall_point + door_size / 2 to end
	self.walls.append([wall_point + (wall_end - wall_point).normalized() * door_size / 2, wall_end])

	# rebuild walls in the scene after this!
	self.door_point = wall_point

	return wall_point


# func _create_walls():
# 	for wall in self.walls:
# 		self._create_wall(wall[0], wall[1])


func activate() -> void:
	print("FlexibleRoom activated at " + str(position))
	self.change()


func change() -> void:
	print("FlexibleRoom changed at " + str(position))


func hide() -> void:
	print("FlexibleRoom hidden at " + str(position))
	for wall in self.wall_nodes:
		wall.visible = false


func show() -> void:
	print("FlexibleRoom shown at " + str(position))
	for wall in self.wall_nodes:
		wall.visible = true


func create_most_open_door() -> Vector2:
	# check all four directions to see which has the most open space

	var TAB = State.TRACKABLE_AREA_BOUNDS
	var north = TAB[1].y - bounds()[1].y
	var south = bounds()[0].y - TAB[0].y
	var east = TAB[1].x - bounds()[1].x
	var west = bounds()[0].x - TAB[0].x

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

	return create_door(direction + position)


func is_point_inside(point: Vector2) -> bool:
	var mins = bounds()[0]
	var maxs = bounds()[1]

	return point.x >= mins.x and point.x <= maxs.x and point.y >= mins.y and point.y <= maxs.y


func is_any_point_inside(points: Array[Vector2]) -> bool:
	for point in points:
		if is_point_inside(point):
			return true
	return false


func point_outside_door() -> Vector2:
	# add a point 1m in each direction orthogonal to the wall the door is on
	var pointA = door_point + door_direction.orthogonal()
	var pointB = door_point - door_direction.orthogonal()

	if not is_point_inside(pointA):
		return pointA
	return pointB
