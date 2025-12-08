extends Control

func _ready():
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

	# Add hover and click sounds to buttons
	_setup_button_sounds($VBoxContainer/StartButton)
	_setup_button_sounds($VBoxContainer/QuitButton)

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
