extends Control

func _ready():
	$VBoxContainer/StartGameButton.pressed.connect(_on_start_game_pressed)
	$VBoxContainer/OptionsButton.pressed.connect(_on_options_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_game_pressed():
	# carica la scena della partita
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_options_pressed():
	print("Options (non implementato)")

func _on_quit_pressed():
	get_tree().quit()
