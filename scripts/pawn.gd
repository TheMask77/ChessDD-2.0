extends Piece
class_name Pawn

const infinite_movement = false

func get_movement_direction() -> int:
	return -1 if color == "white" else 1
