extends Node2D
const BLACK_TILE = preload("res://scenes/Black_Tile.tscn")
const WHITE_TILE = preload("res://scenes/White_Tile.tscn")

const BLACK_BISHOP = preload("res://scenes/Black Pieces/Black_Bishop.tscn")
const BLACK_KING = preload("res://scenes/Black Pieces/Black_King.tscn")
const BLACK_KNIGHT = preload("res://scenes/Black Pieces/Black_Knight.tscn")
const BLACK_PAWN = preload("res://scenes/Black Pieces/Black_Pawn.tscn")
const BLACK_QUEEN = preload("res://scenes/Black Pieces/Black_Queen.tscn")
const BLACK_ROOK = preload("res://scenes/Black Pieces/Black_Rook.tscn")

const WHITE_BISHOP = preload("res://scenes/White Pieces/White_Bishop.tscn")
const WHITE_KING = preload("res://scenes/White Pieces/White_King.tscn")
const WHITE_KNIGHT = preload("res://scenes/White Pieces/White_Knight.tscn")
const WHITE_PAWN = preload("res://scenes/White Pieces/White_Pawn.tscn")
const WHITE_QUEEN = preload("res://scenes/White Pieces/White_Queen.tscn")
const WHITE_ROOK = preload("res://scenes/White Pieces/White_Rook.tscn")

const BLACK_TURN = preload("res://scenes/black_turn.tscn")
const WHITE_TURN = preload("res://scenes/white_turn.tscn")

signal game_over(winner: String, reason: String)

var board_dim = Vector2i(8, 8)
var temporary_tile = WHITE_TILE.instantiate() as Tile
var tile_size = Vector2i(16, 16) # temporary_tile.get_tile_size()
var en_passant_target: Vector2i = Vector2i(-1, -1)

var board = []
var selected_piece = null
var highlighted_tiles: Array[Tile] = []
var white_turn = true
var white_turn_indicator = WHITE_TURN.instantiate()
var black_turn_indicator = BLACK_TURN.instantiate()

func _ready() -> void:
	var tile
	
	add_child(white_turn_indicator)
	add_child(black_turn_indicator)
	white_turn_indicator.global_position = get_board_size() / 2 - Vector2(8, 8)
	black_turn_indicator.global_position = get_board_size() / 2 - Vector2(8, 8)
	update_turn_indicator()
	
	for i in range(board_dim.x):
		board.append([])
		for j in range(board_dim.y):
			if (i + j) % 2 == 1:
				tile = WHITE_TILE.instantiate()
			else:
				tile = BLACK_TILE.instantiate()
				
			add_child(tile)
			tile.position = Vector2(tile_size.x * i, tile_size.y * j)
			tile.board_position = Vector2i(i, j)
			tile.connect("tile_clicked", Callable(self, "_on_tile_clicked"))
			board[i].append(tile)
			
			
	deploy_army("res://armies/standard_black.json")
	deploy_army("res://armies/standard_white.json")

func place_piece(piece_scene: PackedScene, color: String, piece_type: String, board_position: Vector2i):
	var piece = piece_scene.instantiate() as Piece
	piece.color = color
	piece.piece_type = piece_type
	piece.board_position = board_position
	$Pieces.add_child(piece)
	piece.position = board[board_position.x][board_position.y].position
	board[board_position.x][board_position.y].piece = piece

func deploy_army(config_path: String):
	var config = load_army_from_json(config_path)
	for piece_data in config:
		var type = piece_data["type"] as String
		var color = piece_data["color"] as String
		var board_position = Vector2i(piece_data["position"][0], piece_data["position"][1])
		
		var scene: PackedScene
		match type:
			"pawn": 
				scene = BLACK_PAWN if (color == "black") else WHITE_PAWN
			"rook":
				scene = BLACK_ROOK if (color == "black") else WHITE_ROOK
			"knight":
				scene = BLACK_KNIGHT if (color == "black") else WHITE_KNIGHT
			"bishop":
				scene = BLACK_BISHOP if (color == "black") else WHITE_BISHOP
			"queen":
				scene = BLACK_QUEEN if (color == "black") else WHITE_QUEEN
			"king":
				scene = BLACK_KING if (color == "black") else WHITE_KING
		
		place_piece(scene, color, type, board_position)

func load_army_from_json(path: String) -> Array:
	var json_as_text = FileAccess.get_file_as_string(path)
	var army_data = JSON.parse_string(json_as_text)	
	return army_data

func get_board_size() -> Vector2:
	return Vector2(board_dim.x * tile_size.x, board_dim.y * tile_size.y)

func _on_tile_clicked(tile: Tile):
	if tile.piece != null and selected_piece == null:
		if white_turn and tile.piece.color != "white":
			return
		if !white_turn and tile.piece.color == "white":
			return
		
	if selected_piece == null:
		if tile.piece != null:
			selected_piece = tile.piece
			var possible_moves = get_possible_moves(selected_piece)
			show_move_on_board(possible_moves)
	else:
		if tile in highlighted_tiles:
			move_piece(selected_piece, tile)
			clear_highlighted_tiles()
			selected_piece = null
			
		elif tile.piece != null and tile.piece.color == get_current_color():
			clear_highlighted_tiles()
			selected_piece = tile.piece
			var possible_moves = get_possible_moves(selected_piece)
			show_move_on_board(possible_moves)
			
		else:
			clear_highlighted_tiles()
			selected_piece = null

func get_possible_moves(piece: Piece) -> Array[Vector2i]:
	var moves: Array[Vector2i] = []
	var directions = piece.get_move_pattern()
	var infinite = piece.infinite_movement
	
	if piece.piece_type == "pawn":
		return get_pawn_possible_moves(piece)
	
	if piece.piece_type == "king" and not piece.has_moved:
		# arrocco corto (king side)
		if can_castle(piece, true):
			moves.append(piece.board_position + Vector2i(2, 0))

		# arrocco lungo (queen side)
		if can_castle(piece, false):
			moves.append(piece.board_position + Vector2i(-2, 0))
	
	for dir in directions:
		var current_pos = piece.board_position + dir
		
		if infinite:
			while is_within_board(current_pos):
				var tile = board[current_pos.x][current_pos.y]
				if tile.piece != null and tile.piece.color == piece.color:
					break
				if tile.piece == null:
					moves.append(current_pos)
				else:
					if tile.piece.color != piece.color:
						moves.append(current_pos)
						break
				current_pos += dir
		else:
			if is_within_board(current_pos):
				var tile = board[current_pos.x][current_pos.y]
				if tile.piece == null || tile.piece.color != piece.color:
					moves.append(current_pos)
	return moves

func get_pawn_possible_moves(pawn: Pawn) -> Array[Vector2i]:
	var moves : Array[Vector2i] = []
	var movement_direction = pawn.get_movement_direction()
	var is_in_starting_row = true if pawn.board_position.y == 1 or pawn.board_position.y == 6 else false
	
	var forward_1 = pawn.board_position + Vector2i(0, movement_direction)
	if is_within_board(forward_1) and board[forward_1.x][forward_1.y].piece == null:
		moves.append(forward_1)
		var forward_2 = pawn.board_position + Vector2i(0, movement_direction * 2)
		if is_in_starting_row and board[forward_2.x][forward_2.y].piece == null:
			moves.append(forward_2)
	
	for dx in [-1, 1]:
		var diag = pawn.board_position + Vector2i(dx, movement_direction)
		if is_within_board(diag):
			var target_tile = board[diag.x][diag.y]
			if target_tile.piece != null and target_tile.piece.color != pawn.color:
				moves.append(diag)
			elif diag == en_passant_target:
				moves.append(diag)
	
	return moves

func show_move_on_board(moves: Array[Vector2i]):
	for move in moves:
		var tile = board[move.x][move.y]
		tile.show_highlight()
		highlighted_tiles.append(tile)

func clear_highlighted_tiles():
	for tile in highlighted_tiles:
		tile.hide_highlight()
	highlighted_tiles.clear()	

func move_piece(piece: Piece, target_tile: Tile):
	
	if piece.piece_type == "king" and abs(target_tile.board_position.x - piece.board_position.x) == 2:
		var y = piece.board_position.y
		var rook_tile
		var new_rook_pos
		var rook
		if target_tile.board_position.x > piece.board_position.x:
			# arrocco corto
			rook_tile = board[7][y]
			rook = rook_tile.piece
			new_rook_pos = board[5][y]
		else:
			# arrocco lungo
			rook_tile = board[0][y]
			rook = rook_tile.piece
			new_rook_pos = board[3][y]

		# sposta la torre
		board[rook_tile.board_position.x][y].piece = null
		rook.board_position = new_rook_pos.board_position
		new_rook_pos.piece = rook
		rook.position = new_rook_pos.position
		rook.has_moved = true

	
	if piece.piece_type == "pawn" and target_tile.board_position == en_passant_target:
		var captured_pawn_pos = Vector2i(target_tile.board_position.x, target_tile.board_position.y - piece.get_movement_direction())
		var captured_pawn_tile = board[captured_pawn_pos.x][captured_pawn_pos.y]
		print("Removing en-p'd pawn at: ", captured_pawn_pos)
		if captured_pawn_tile.piece != null:
			captured_pawn_tile.piece.queue_free()
			captured_pawn_tile.piece = null
	
	if target_tile.piece != null and target_tile.piece.color != piece.color:
		print("Chomp")
		target_tile.piece.queue_free()
	
	if piece.piece_type == "pawn":
		var start_row = 6 if piece.color == "white" else 1
		if abs(target_tile.board_position.y - piece.board_position.y) == 2 and piece.board_position.y == start_row:
			en_passant_target = Vector2i(piece.board_position.x, piece.board_position.y + piece.get_movement_direction())
			print("Registering en-p target: ", en_passant_target)
		else:
			en_passant_target = Vector2i(-1, -1)
	else:
		en_passant_target = Vector2i(-1, -1)
		
	board[piece.board_position.x][piece.board_position.y].piece = null
	piece.board_position = target_tile.board_position
	target_tile.piece = piece
	piece.position = target_tile.position
	piece.has_moved = true
	switch_turn()

func is_within_board(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < board_dim.x and pos.y < board_dim.y

func update_turn_indicator():
	white_turn_indicator.visible = white_turn
	black_turn_indicator.visible = !white_turn

func switch_turn():
	white_turn = !white_turn
	update_turn_indicator()
	check_game_end()

func get_king(color: String) -> Node:
	for piece in get_all_pieces(color):
		if piece.piece_type == "king":
			return piece
	return null

func get_all_pieces(color: String) -> Array:
	var pieces := []
	for child in $Pieces.get_children():
		if child.color == color:
			pieces.append(child)
	return pieces

func is_square_attacked(tile: Tile, by_color: String) -> bool:
	var enemy_pieces = get_all_pieces(by_color)
	for piece in enemy_pieces:
		var moves = get_possible_moves(piece)
		if tile.board_position in moves:
			return true
	return false

func is_king_in_check(color: String) -> bool:
	var king = get_king(color) as King
	if king == null:
		return false
	var king_tile = board[king.board_position.x][king.board_position.y] as Tile
	var enemy_color = "white" if king.color == "black" else "black"
	var is_king_in_check = is_square_attacked(king_tile, enemy_color)
	return is_king_in_check

func get_current_color() -> String:
	return "white" if white_turn else "black"

func opposite_color(color: String) -> String:
	return "black" if color == "white" else "white"

func check_game_end():
	var current_color = get_current_color()
	var king = get_king(current_color)

	# Caso 1: il re non esiste più
	if king == null:
		end_game(opposite_color(current_color), "king_captured")
		return

	# Caso 2: il re esiste
	var in_check = is_king_in_check(current_color)
	var can_move = has_legal_moves(current_color)

	if not can_move:
		if in_check:
			end_game(opposite_color(current_color), "checkmate")
		else:
			end_game("draw", "stalemate")
	# Altrimenti: partita continua

func has_legal_moves(color: String) -> bool:
	for piece in get_all_pieces(color):
		var moves = get_possible_moves(piece)
		for move in moves:
			# Simulazione: spostiamo temporaneamente il pezzo
			var from_tile = board[piece.board_position.x][piece.board_position.y]
			var to_tile = board[move.x][move.y]
			var captured = to_tile.piece

			# Applichiamo la mossa
			from_tile.piece = null
			to_tile.piece = piece
			var old_pos = piece.board_position
			piece.board_position = move

			var still_in_check = is_king_in_check(color)

			# Rollback della mossa
			piece.board_position = old_pos
			from_tile.piece = piece
			to_tile.piece = captured

			if not still_in_check:
				return true  # almeno una mossa legale trovata
	return false

func end_game(winner: String, reason: String) -> void:
	emit_signal("game_over", winner, reason)

func can_castle(king: Piece, king_side: bool) -> bool:
	var king_y = king.board_position.y
	var king_x = king.board_position.x
	var color = king.color

	# torre di riferimento
	var rook_x = 7 if king_side else 0
	var rook = board[rook_x][king_y].piece
	if rook == null or rook.piece_type != "rook" or rook.has_moved:
		return false

	# caselle intermedie libere
	var step = 1 if king_side else -1
	for i in range(king_x + step, rook_x, step):
		if board[i][king_y].piece != null:
			return false

	# re non deve passare per caselle attaccate
	for i in range(0, 3): # max 2 caselle da controllare
		var pos = Vector2i(king_x + step * i, king_y)
		if is_square_attacked(board[pos.x][pos.y], opposite_color(color)):
			return false

	return true
