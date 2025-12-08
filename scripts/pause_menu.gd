extends Control

func _ready():
	$VBoxContainer2/ResumeButton.pressed.connect(_on_resume_pressed)
	$VBoxContainer2/QuitButton.pressed.connect(_on_quit_pressed)
	visible = false

	# Add hover and click sounds to buttons
	_setup_button_sounds($VBoxContainer2/ResumeButton)
	_setup_button_sounds($VBoxContainer2/QuitButton)

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

func _on_resume_pressed():
	if get_tree().paused == true:
		get_tree().paused = false
		visible = false

func _on_quit_pressed():
	if get_tree().paused == true:
		get_tree().quit()

func _input(event):
	if event.is_action_pressed("pause"):
		get_tree().paused = !get_tree().paused
		visible = get_tree().paused
