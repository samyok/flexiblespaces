extends Node

# config
const TRACKABLE_AREA_BOUNDS = [Vector2(0, 0), Vector2(10, 10)]  # min (x, y)  # max (x, y)

const ROOM_SIZE = 4  # try not to change this, it's hard coded in some places

# state
var rooms: Array[FlexibleRoom] = []
var paths: Array[RightAngledPath] = [null]  # path _to_ room
var current_room = null

enum LOCATION { ROOM, PORTAL, PATH }
var location = LOCATION.ROOM


func add_room(room):
	rooms.append(room)
	if current_room == null:
		current_room = rooms.size() - 1
