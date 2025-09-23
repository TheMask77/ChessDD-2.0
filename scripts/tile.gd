extends Node
class_name Tile

var piece: Piece
var board_position: Vector2i
signal tile_clicked(tile_ref: Tile)


@onready var default_sprite: Sprite2D = $Default
@onready var highlight_sprite: Sprite2D = $Highlight

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	highlight_sprite.visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func get_tile_size() -> Vector2i:
	return default_sprite.get_size()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("tile_clicked", self)

func show_highlight():
	highlight_sprite.visible = true

func hide_highlight():
	highlight_sprite.visible = false
