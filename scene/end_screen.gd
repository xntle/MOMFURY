extends Control

var final_points: int = 0
var final_round: int = 0
var high_score: int = 0
var high_round: int = 0
var is_new_high_score: bool = false
var is_new_high_round: bool = false

const SAVE_FILE = "user://highscores.save"

func _ready():
	# Load high scores
	_load_high_scores()

	# Check if new high score
	is_new_high_score = final_points > high_score
	is_new_high_round = final_round > high_round

	# Update high scores if needed
	if is_new_high_score:
		high_score = final_points
	if is_new_high_round:
		high_round = final_round

	# Save new high scores
	if is_new_high_score or is_new_high_round:
		_save_high_scores()

	# Display scores
	$VBoxContainer2/FinalPoints.text = "Points: %d" % final_points
	$VBoxContainer2/FinalRound.text  = "Round: %d" % final_round

	# Add high score display
	_display_high_scores()

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

func _load_high_scores() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		high_score = file.get_32()
		high_round = file.get_32()
		file.close()
	else:
		# No save file yet, default to 0
		high_score = 0
		high_round = 0

func _save_high_scores() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_32(high_score)
		file.store_32(high_round)
		file.close()

func _display_high_scores() -> void:
	# Create a label for high scores if it doesn't exist
	var high_score_container = get_node_or_null("VBoxContainer2/HighScoreContainer")
	if high_score_container == null:
		# Create container for high scores
		high_score_container = VBoxContainer.new()
		high_score_container.name = "HighScoreContainer"
		$VBoxContainer2.add_child(high_score_container)

		# Add spacing
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 20)
		high_score_container.add_child(spacer)

		# High score label
		var high_score_label = Label.new()
		high_score_label.name = "HighScoreLabel"
		high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		high_score_label.add_theme_font_override("font", load("res://assets/fonts/MegamaxJonathanToo-YqOq2.ttf"))
		high_score_label.add_theme_font_size_override("font_size", 24)
		high_score_label.text = "High Score: %d" % high_score
		high_score_container.add_child(high_score_label)

		# High round label
		var high_round_label = Label.new()
		high_round_label.name = "HighRoundLabel"
		high_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		high_round_label.add_theme_font_override("font", load("res://assets/fonts/MegamaxJonathanToo-YqOq2.ttf"))
		high_round_label.add_theme_font_size_override("font_size", 24)
		high_round_label.text = "High Round: %d" % high_round
		high_score_container.add_child(high_round_label)

		# New high score announcement
		if is_new_high_score or is_new_high_round:
			var new_high_label = Label.new()
			new_high_label.name = "NewHighLabel"
			new_high_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			new_high_label.add_theme_font_override("font", load("res://assets/fonts/MegamaxJonathanToo-YqOq2.ttf"))
			new_high_label.add_theme_font_size_override("font_size", 32)
			new_high_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))  # Gold color
			new_high_label.text = "NEW HIGH SCORE!"
			high_score_container.add_child(new_high_label)

			# Make it blink
			_make_label_blink(new_high_label)

func _make_label_blink(label: Label) -> void:
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(label, "modulate:a", 0.3, 0.5)
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
