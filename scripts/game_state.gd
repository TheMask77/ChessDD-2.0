extends Node
class_name GameState

# Rappresenta lo stato "logico" della scacchiera, pezzi, en-passant, ecc.
# Espone API per leggere/modificare lo stato e per apply/undo di mosse (utile per simulazioni).

var board_dim: Vector2i = Vector2i(8, 8)
var tile_size: Vector2i = Vector2i(16, 16)

# board[x][y] = Tile (o null se non ancora inizializzato)
var board := []

# en_passant target (posizione dove un pedone può essere catturato via en-passant)
var en_passant_target: Vector2i = Vector2i(-1, -1)

func _init():
	# crea struttura vuota
	board.clear()
	for i in range(board_dim.x):
		board.append([])
		for j in range(board_dim.y):
			board[i].append(null)

# ---------- lettori utili ----------
func is_within_board(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.y >= 0 and pos.x < board_dim.x and pos.y < board_dim.y

func get_tile(pos: Vector2i):
	if not is_within_board(pos):
		return null
	return board[pos.x][pos.y]

func get_piece(pos: Vector2i):
	var t = get_tile(pos)
	return t.piece if t != null else null

func get_all_pieces(color: String) -> Array:
	var pieces := []
	if has_node(".."): # not necessary, but keep safe
		for child in get_tree().get_nodes_in_group("pieces"):
			if child.color == color:
				pieces.append(child)
	return pieces

func get_king(color: String):
	for child in get_tree().get_nodes_in_group("pieces"):
		if child.color == color and child.piece_type == "king":
			return child
	return null

# ---------- impostazione iniziale / piazzamento ----------
func set_tile(tile_obj, pos: Vector2i) -> void:
	board[pos.x][pos.y] = tile_obj

func place_piece_instance(piece: Node2D, pos: Vector2i) -> void:
	# pos è Vector2i board coords
	var tile = get_tile(pos)
	if tile == null:
		push_error("Trying to place piece on null tile: %s" % pos)
		return
	# attach piece under scene's Pieces node? left to GameManager: it should add child to container.
	piece.board_position = pos
	tile.piece = piece
	# set visual position according to tile
	piece.position = tile.position

# ---------- apply / undo move (per simulazioni e gioco reale) ----------
# apply_move ritorna un dict con info per poter fare undo_move
func apply_move(piece: Node, target_pos: Vector2i) -> Dictionary:
	var from_pos = piece.board_position
	var from_tile = get_tile(from_pos)
	var to_tile = get_tile(target_pos)
	var meta = {
		"piece": piece,
		"from_pos": from_pos,
		"to_pos": target_pos,
		"captured": null,
		"was_en_passant": false,
		"prev_en_passant": en_passant_target,
		"was_castling": false,
		"rook": null,
		"rook_from": null,
		"rook_to": null
	}

	# handle en-passant capture
	if piece.piece_type == "pawn" and target_pos == en_passant_target:
		var captured_pawn_pos = Vector2i(target_pos.x, target_pos.y - piece.get_movement_direction())
		var captured_tile = get_tile(captured_pawn_pos)
		if captured_tile and captured_tile.piece:
			meta["captured"] = captured_tile.piece
			meta["was_en_passant"] = true
			# remove visually & logically
			# captured_tile.piece.queue_free()
			show_capture_piece(captured_tile.piece)
			captured_tile.piece = null

	# handle normal capture
	if to_tile.piece != null and to_tile.piece != piece:
		meta["captured"] = to_tile.piece
		# free captured node (for the real game). For simulation we keep null but queue_free for real moves.
		show_capture_piece(to_tile.piece)
		# to_tile.piece.queue_free()
		to_tile.piece = null

	# handle castling (only king moves of 2 files)
	if piece.piece_type == "king" and abs(target_pos.x - from_pos.x) == 2:
		meta["was_castling"] = true
		var rook_from_x = 7 if target_pos.x > from_pos.x else 0
		var rook_to_x = 5 if target_pos.x > from_pos.x else 3
		var rook_from = get_tile(Vector2i(rook_from_x, from_pos.y))
		if rook_from and rook_from.piece:
			var rook = rook_from.piece
			meta["rook"] = rook
			meta["rook_from"] = rook_from.board_position
			meta["rook_to"] = Vector2i(rook_to_x, from_pos.y)
			# move rook
			rook_from.piece = null
			var rook_to_tile = get_tile(meta["rook_to"])
			rook.board_position = meta["rook_to"]
			rook_to_tile.piece = rook
			rook.position = rook_to_tile.position
			rook.has_moved = true

	# set en_passant target for double pawn move
	if piece.piece_type == "pawn":
		var start_row = 6 if piece.color == "white" else 1
		if abs(target_pos.y - from_pos.y) == 2 and from_pos.y == start_row:
			en_passant_target = Vector2i(from_pos.x, from_pos.y + piece.get_movement_direction())
		else:
			en_passant_target = Vector2i(-1, -1)
	else:
		en_passant_target = Vector2i(-1, -1)

	# move piece logically
	from_tile.piece = null
	to_tile.piece = piece
	piece.board_position = target_pos
	# piece.position = to_tile.position
	meta["prev_has_moved"] = piece.has_moved
	piece.has_moved = true

	return meta

# undo_move usa i dati prodotti da apply_move
func undo_move(meta: Dictionary) -> void:
	var piece = meta["piece"]
	var from_pos: Vector2i = meta["from_pos"]
	var to_pos: Vector2i = meta["to_pos"]

	# move piece back
	var from_tile = get_tile(from_pos)
	var to_tile = get_tile(to_pos)
	to_tile.piece = null
	from_tile.piece = piece
	piece.board_position = from_pos
	piece.position = from_tile.position
	piece.has_moved = meta.get("prev_has_moved", false)

	# restore captured piece (se presente)
	if meta["was_en_passant"]:
		var captured_pos = Vector2i(to_pos.x, to_pos.y - piece.get_movement_direction())
		var cap_tile = get_tile(captured_pos)
		if meta["captured"] != null:
			# nota: qui ricreiamo il nodo catturato? la soluzione semplice è ri-instantiare dallo scene pack se necessario.
			# Per la simulazione possiamo ri-assegnare l'oggetto se non è stato freed; nel caso reale, catturati venivano queue_free()
			cap_tile.piece = meta["captured"]
			cap_tile.piece.board_position = captured_pos
			cap_tile.piece.position = cap_tile.position
	else:
		if meta["captured"] != null:
			# se il captured era su to_tile, ripristiniamo
			to_tile.piece = meta["captured"]
			to_tile.piece.board_position = to_pos
			to_tile.piece.position = to_tile.position

	# undo castling rook move
	if meta["was_castling"] and meta["rook"] != null:
		var rook = meta["rook"]
		var rook_from = meta["rook_from"]
		var rook_to = meta["rook_to"]
		var rook_from_tile = get_tile(rook_from)
		var rook_to_tile = get_tile(rook_to)
		# sposta rook al from
		rook_to_tile.piece = null
		rook_from_tile.piece = rook
		rook.board_position = rook_from
		rook.position = rook_from_tile.position
		rook.has_moved = false

	# restore en_passant
	en_passant_target = meta.get("prev_en_passant", Vector2i(-1, -1))

func move_piece_sprite(piece: Piece, to_tile: Tile):
	var tween = get_tree().create_tween()
	tween.tween_property(piece, "position", to_tile.position, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func show_capture_piece(piece: Piece):
	var tween = get_tree().create_tween()
	tween.tween_property(piece, "modulate:a", 0.0, 0.3) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func(): piece.queue_free())
