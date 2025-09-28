extends Node2D
class_name Piece

var color: String = ""
var board_position: Vector2i = Vector2i(-1, -1)
var piece_type: String = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	global_position = Vector2i(board_position.x * 16, board_position.y * 16)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func get_move_pattern() -> Array[Vector2i]:
	return []

func _to_string() -> String:
	return str(color, " ", piece_type, " at ", board_position)
