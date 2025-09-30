extends Node2D
class_name GameManager

signal game_over(winner: String, reason: String)
signal turn_changed(color: String)

const BLACK_TILE = preload("res://scenes/Black_Tile.tscn")
const WHITE_TILE = preload("res://scenes/White_Tile.tscn")

const BLACK_PAWN = preload("res://scenes/Black Pieces/Black_Pawn.tscn")
const BLACK_ROOK = preload("res://scenes/Black Pieces/Black_Rook.tscn")
const BLACK_KNIGHT = preload("res://scenes/Black Pieces/Black_Knight.tscn")
const BLACK_BISHOP = preload("res://scenes/Black Pieces/Black_Bishop.tscn")
const BLACK_QUEEN = preload("res://scenes/Black Pieces/Black_Queen.tscn")
const BLACK_KING = preload("res://scenes/Black Pieces/Black_King.tscn")

const WHITE_PAWN = preload("res://scenes/White Pieces/White_Pawn.tscn")
const WHITE_ROOK = preload("res://scenes/White Pieces/White_Rook.tscn")
const WHITE_KNIGHT = preload("res://scenes/White Pieces/White_Knight.tscn")
const WHITE_BISHOP = preload("res://scenes/White Pieces/White_Bishop.tscn")
const WHITE_QUEEN = preload("res://scenes/White Pieces/White_Queen.tscn")
const WHITE_KING = preload("res://scenes/White Pieces/White_King.tscn")

@onready var turn_indicator: TurnIndicator = $"../TurnIndicator"
@onready var pieces_container = $Pieces

var game_state: GameState
var move_gen: MoveGenerator

# UI state
var selected_piece = null
var highlighted_tiles: Array = []
var white_turn := true

func _ready() -> void:
	# crea oggetti di supporto
	game_state = GameState.new()
	add_child(game_state) # opzionale: utile per is_within_board
	move_gen = MoveGenerator.new()
	add_child(move_gen)

	# crea board grafica (tiles) e registra tiles nel game_state
	_create_tiles()

	# turn indicators
	turn_indicator.global_position = get_board_size() / 2 - Vector2(8, 8)
	_update_turn_indicator()

	# deploy armies
	_deploy_army("res://armies/standard_black.json")
	_deploy_army("res://armies/standard_white.json")

func _create_tiles() -> void:
	var tmp = WHITE_TILE.instantiate()
	var tile_sz = tmp.get_tile_size()
	tmp.queue_free()
	game_state.tile_size = tile_sz

	for i in range(game_state.board_dim.x):
		for j in range(game_state.board_dim.y):
			var tile_scene = WHITE_TILE if (i + j) % 2 == 1 else BLACK_TILE
			var tile = tile_scene.instantiate()
			add_child(tile)
			tile.position = Vector2(tile_sz.x * i, tile_sz.y * j)
			tile.board_position = Vector2i(i, j)
			tile.connect("tile_clicked", Callable(self, "_on_tile_clicked"))
			game_state.set_tile(tile, Vector2i(i, j))

func get_board_size() -> Vector2:
	return Vector2(game_state.board_dim.x * game_state.tile_size.x, game_state.board_dim.y * game_state.tile_size.y)

# ---------- army deploy ----------
func _deploy_army(path: String) -> void:
	var json_text = FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("army json parse error: %s" % path)
		return
	for item in parsed:
		var type = item["type"]
		var color = item["color"]
		var pos = Vector2i(item["position"][0], item["position"][1])
		var piece_scene : PackedScene = _scene_for_type(type, color)
		if piece_scene:
			var piece_inst = piece_scene.instantiate()
			# aggiungi al gruppo pieces per lookup (usato da move_generator)
			piece_inst.add_to_group("pieces")
			pieces_container.add_child(piece_inst)
			piece_inst.color = color
			piece_inst.piece_type = type
			piece_inst.board_position = pos
			game_state.place_piece_instance(piece_inst, pos)

func _scene_for_type(type: String, color: String) -> PackedScene:
	var piece_scene : PackedScene
	match type:
		"pawn": piece_scene = BLACK_PAWN if color == "black" else WHITE_PAWN
		"rook": piece_scene = BLACK_ROOK if color == "black" else WHITE_ROOK
		"knight": piece_scene = BLACK_KNIGHT if color == "black" else WHITE_KNIGHT
		"bishop": piece_scene = BLACK_BISHOP if color == "black" else WHITE_BISHOP
		"queen": piece_scene = BLACK_QUEEN if color == "black" else WHITE_QUEEN
		"king": piece_scene = BLACK_KING if color == "black" else WHITE_KING
	return piece_scene

# ---------- Input handling ----------
func _on_tile_clicked(tile: Tile) -> void:
	print("Clicked tile at: ", tile.board_position)
	# turn validation
	if tile.piece != null and selected_piece == null:
		if white_turn and tile.piece.color != "white":
			return
		if not white_turn and tile.piece.color == "white":
			return

	if selected_piece == null:
		if tile.piece != null:
			selected_piece = tile.piece
			var possible = move_gen.get_possible_moves(game_state, selected_piece)
			_show_moves(possible)
	else:
		if tile in highlighted_tiles:
			_perform_move(selected_piece, tile)
			_clear_highlight()
			selected_piece = null
		elif tile.piece != null and tile.piece.color == _current_color():
			_clear_highlight()
			selected_piece = tile.piece
			var possible = move_gen.get_possible_moves(game_state, selected_piece)
			_show_moves(possible)
		else:
			_clear_highlight()
			selected_piece = null

func _show_moves(moves: Array) -> void:
	for m in moves:
		var t = game_state.get_tile(m)
		if t:
			t.show_highlight()
			highlighted_tiles.append(t)

func _clear_highlight() -> void:
	for t in highlighted_tiles:
		t.hide_highlight()
	highlighted_tiles.clear()

func _perform_move(piece: Node, target_tile: Tile) -> void:
	# apply move via game_state (che si occuperà anche di en-passant / castling / has_moved)
	var meta = game_state.apply_move(piece, target_tile.board_position)
	# nel tuo codice precedente veniva fatto queue_free sui catturati; apply_move già chiama queue_free dove appropriato
	game_state.move_piece_on_board(piece, target_tile)
	# switch turn e check fine partita
	_switch_turn()
	_check_game_end()

func _switch_turn() -> void:
	white_turn = !white_turn
	_update_turn_indicator()

func _update_turn_indicator() -> void:
	emit_signal("turn_changed", white_turn)

func _current_color() -> String:
	return "white" if white_turn else "black"

# ---------- fine partita ----------
func _check_game_end() -> void:
	var current_color = _current_color()
	var king = game_state.get_king(current_color)
	if king == null:
		emit_signal("game_over", ( "white" if current_color == "black" else "black"), "king_captured")
		return

	var in_check = move_gen.is_king_in_check(game_state, current_color)
	var can_move = _has_legal_moves(current_color)
	if not can_move:
		if in_check:
			emit_signal("game_over", ( "white" if current_color == "black" else "black"), "checkmate")
		else:
			emit_signal("game_over", "draw", "stalemate")

func _has_legal_moves(color: String) -> bool:
	# Simula ogni mossa e verifica che non lasci il re in scacco
	for piece in get_tree().get_nodes_in_group("pieces"):
		if piece.color != color:
			continue
		var moves = move_gen.get_possible_moves(game_state, piece)
		for m in moves:
			# apply temporaneo
			var meta = game_state.apply_move(piece, m)
			var still_in_check = move_gen.is_king_in_check(game_state, color)
			# undo
			game_state.undo_move(meta)
			if not still_in_check:
				return true
	return false
