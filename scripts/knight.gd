extends Piece
class_name Knight

const infinite_movement = false

func get_move_pattern() -> Array[Vector2i]:
	return [
		Vector2i(1,2), Vector2i(-1,2),
		Vector2i(1,-2), Vector2i(-1,-2),
		Vector2i(2,1), Vector2i(-2,1),
		Vector2i(2,-1), Vector2i(-2,-1),
	]
