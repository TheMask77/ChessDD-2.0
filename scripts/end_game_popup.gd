extends PopupPanel

@onready var label: Label = $MarginContainer/VBoxContainer/Label
@onready var restart_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/RestartButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/HBoxContainer/QuitButton

signal restart_requested
signal quit_requested

func _ready() -> void:
	restart_button.text = "Restart"
	quit_button.text = "Quit"

func show_end_game(winner: String, reason: String):
	match reason:
		"checkmate":
			label.text = "Scacco matto! Ha vinto %s" % winner
		"stalemate":
			label.text = "Stallo! La partita è patta"
		"king_captured":
			label.text = "Re catturato! Ha vinto %s" % winner
		_:
			label.text = "Fine partita"
	popup_centered()

func _on_restart_button_pressed() -> void:
	print("Pressed restart")
	emit_signal("restart_requested")


func _on_quit_button_pressed() -> void:
	print("Pressed quit")
	emit_signal("quit_requested")
