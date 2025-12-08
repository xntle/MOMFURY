extends Control

var final_points: int = 0
var final_round: int = 0

func _ready():
	$VBoxContainer2/FinalPoints.text = "Points: %d" % final_points
	$VBoxContainer2/FinalRound.text  = "Round: %d" % final_round

	$VBoxContainer/StartButton.text = "Play Again"
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

	# Add hover and click sounds to buttons
	_setup_button_sounds($VBoxContainer/StartButton)
	_setup_button_sounds($VBoxContainer/QuitButton)

	# Play game over audio
	_play_gameover_audio()

func _play_gameover_audio() -> void:
	var gameover_sound = load("res://assets/Sound/The Price is Right Losing Horn - Sound Effect (HD).mp3") as AudioStream
	if gameover_sound != null:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = gameover_sound
		audio_player.play()

		# Cleanup after finished
		audio_player.finished.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

func _setup_button_sounds(button: Button) -> void:
	# Hover sound
	button.mouse_entered.connect(func():
		_play_ui_sound("res://assets/Sound/hover.mp3")
	)

	# Click sound
	button.pressed.connect(func():
		_play_ui_sound("res://assets/Sound/click.mp3")
	)

func _play_ui_sound(sound_path: String) -> void:
	var sound = load(sound_path) as AudioStream
	if sound != null:
		var audio_player = AudioStreamPlayer.new()
		add_child(audio_player)
		audio_player.stream = sound
		audio_player.play()

		# Cleanup after finished
		audio_player.finished.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

func _on_start_pressed():
	get_tree().change_scene_to_file("res://scene/Game.tscn")

func _on_quit_pressed():
	get_tree().quit()
