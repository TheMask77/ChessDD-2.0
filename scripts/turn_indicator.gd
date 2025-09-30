extends Node2D
class_name TurnIndicator

@onready var white_indicator = $WhiteTurnSprite
@onready var black_indicator = $BlackTurnSprite

func _ready():
	# Recupero GameManager in scena (adatta il percorso al tuo albero)
	var gm = get_node("../Board")  # se GameManager è attaccato a Board
	gm.turn_changed.connect(_on_turn_changed)

func _on_turn_changed(white_turn: bool) -> void:
	white_indicator.visible = white_turn
	black_indicator.visible = !white_turn
