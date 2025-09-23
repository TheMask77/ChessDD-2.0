extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var board_center = $Board.get_board_size() / 2
	$Camera2D.global_position = Vector2(board_center.x - 8, board_center.y - 8)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
