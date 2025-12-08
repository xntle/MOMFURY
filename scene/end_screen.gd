extends Control

var final_points: int = 0
var final_round: int = 0

func _ready():
	$VBoxContainer2/FinalPoints.text = "Points: %d" % final_points
	$VBoxContainer2/FinalRound.text  = "Round: %d" % final_round

	$VBoxContainer/StartButton.text = "Play Again"
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scene/Game.tscn")

func _on_quit_pressed():
	get_tree().quit()
