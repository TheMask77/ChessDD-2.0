extends Piece
class_name King

const infinite_movement = false

func get_move_pattern() -> Array[Vector2i]:
	return [
		Vector2i(1,0), Vector2i(-1,0), 
		Vector2i(0,1), Vector2i(0,-1),
		Vector2i(1,1), Vector2i(1,-1), 
		Vector2i(-1,1), Vector2i(-1,-1)
	]
