extends MeshInstance3D

var DFS_button
var BFS_button

func _ready():
	DFS_button = self.find_child("DFS_button")
	BFS_button = self.find_child("BFS_button")

func _on_left_hand(area):
	if area == DFS_button:
		self.hide()
	elif area == BFS_button:
		self.hide()

func _on_right_hand(area):
	if area == DFS_button:
		self.hide()
	elif area == BFS_button:
		self.hide()
