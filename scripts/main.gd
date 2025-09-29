extends Node2D
@onready var end_game_popup: PopupPanel = $EndGamePopup

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var board_center = $Board.get_board_size() / 2
	$Camera2D.global_position = Vector2(board_center.x - 8, board_center.y - 8)

func _on_board_game_over(winner: String, reason: String) -> void:
	print("Game ended")
	end_game_popup.show_end_game("test", "test")

func _on_end_game_popup_quit_requested() -> void:
	print("Pressed quit")
	get_tree().quit()

func _on_end_game_popup_restart_requested() -> void:
	print("Pressed restart")
	get_tree().reload_current_scene()


func _on_button_test_press_signal() -> void:
	print("Signal received")
