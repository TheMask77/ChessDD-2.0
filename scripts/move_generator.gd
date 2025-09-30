extends Node
class_name MoveGenerator

# Dipendenze: si aspetta che GameState sia disponibile (passarlo nei metodi)
# Contiene tutta la logica per generazione mosse (senza effetti collaterali)
# Usa i dati sullo stato dalla GameState (board, en_passant_target).

func get_possible_moves(game_state: GameState, piece: Node) -> Array:
	var moves: Array = []
	if piece == null:
		return moves

	# gestione pedone
	if piece.piece_type == "pawn":
		return get_pawn_possible_moves(game_state, piece)

	var directions = piece.get_move_pattern()
	var infinite = piece.infinite_movement if "infinite_movement" in piece else false

	# gestione re (arrocco incluso) - arrocco è valutato qui
	if piece.piece_type == "king" and not piece.has_moved:
		# king side
		if can_castle(game_state, piece, true):
			moves.append(piece.board_position + Vector2i(2, 0))
		# queen side
		if can_castle(game_state, piece, false):
			moves.append(piece.board_position + Vector2i(-2, 0))

	for dir in directions:
		var current_pos = piece.board_position + dir
		if infinite:
			while game_state.is_within_board(current_pos):
				var tile = game_state.get_tile(current_pos)
				if tile.piece != null and tile.piece.color == piece.color:
					break
				if tile.piece == null:
					moves.append(current_pos)
				else:
					moves.append(current_pos)
					break
				current_pos += dir
		else:
			if game_state.is_within_board(current_pos):
				var tile = game_state.get_tile(current_pos)
				if tile.piece == null or tile.piece.color != piece.color:
					moves.append(current_pos)
	return moves

func get_pawn_possible_moves(game_state: GameState, pawn: Node) -> Array:
	var moves := []
	var movement_direction = pawn.get_movement_direction()
	var is_in_starting_row = pawn.board_position.y == 1 or pawn.board_position.y == 6

	var forward_1 = pawn.board_position + Vector2i(0, movement_direction)
	if game_state.is_within_board(forward_1) and game_state.get_tile(forward_1).piece == null:
		moves.append(forward_1)
		var forward_2 = pawn.board_position + Vector2i(0, movement_direction * 2)
		if is_in_starting_row and game_state.is_within_board(forward_2) and game_state.get_tile(forward_2).piece == null:
			moves.append(forward_2)

	for dx in [-1, 1]:
		var diag = pawn.board_position + Vector2i(dx, movement_direction)
		if game_state.is_within_board(diag):
			var target_tile = game_state.get_tile(diag)
			if target_tile.piece != null and target_tile.piece.color != pawn.color:
				moves.append(diag)
			elif diag == game_state.en_passant_target:
				moves.append(diag)
	return moves

func can_castle(game_state: GameState, king: Node, king_side: bool) -> bool:
	if king.has_moved:
		return false
	var y = king.board_position.y
	var king_x = king.board_position.x
	var rook_x = 7 if king_side else 0
	var rook_tile = game_state.get_tile(Vector2i(rook_x, y))
	if rook_tile == null or rook_tile.piece == null or rook_tile.piece.piece_type != "rook" or rook_tile.piece.has_moved:
		return false

	var step = 1 if king_side else -1
	# check intermediate squares empty
	for i in range(king_x + step, rook_x, step):
		if game_state.get_tile(Vector2i(i, y)).piece != null:
			return false

	# check squares king passes through not attacked
	var enemy_color = "white" if king.color == "black" else "black"
	for i in range(0, 3):
		var pos = Vector2i(king_x + step * i, y)
		if is_square_attacked(game_state, pos, enemy_color):
			return false

	return true

func is_square_attacked(game_state: GameState, pos: Vector2i, by_color: String) -> bool:
	# usa la generation di mosse sugli avversari: nota che get_possible_moves richiede GameState e piece
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.color != by_color:
			continue
		var cand_moves = get_possible_moves(game_state, piece)
		# per i pedoni, la get_pawn_possible_moves già ritorna le diagonali di cattura e en-passant
		if pos in cand_moves:
			return true
	return false

# wrapper compatibile con la tua API precedente
func is_king_in_check(game_state: GameState, color: String) -> bool:
	var king = game_state.get_king(color)
	if king == null:
		return false
	return is_square_attacked(game_state, king.board_position, ( "white" if king.color == "black" else "black" ))
