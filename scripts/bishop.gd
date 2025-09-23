extends Piece
class_name Bishop

const infinite_movement = true

func get_move_pattern() -> Array[Vector2i]:
	return [
		Vector2i(1,1), Vector2i(-1,1),
		Vector2i(1,-1), Vector2i(-1,-1)
	]
