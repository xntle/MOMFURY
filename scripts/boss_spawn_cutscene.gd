extends Node
class_name BossSpawnCutscene

signal cutscene_finished

@export var boss_scene: PackedScene
@export var boss_spawn_position: Vector2 = Vector2(300, 150)
@export var earthquake_duration: float = 2.0
@export var camera_pan_duration: float = 1.5
@export var text_display_duration: float = 2.0

var player: Node2D
var camera: Camera2D
var boss_text_label: Label
var is_playing: bool = false

func play_cutscene() -> void:
	if is_playing:
		return

	is_playing = true

	# Find player and camera
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		player = get_node_or_null("/root/Game/Player")

	if player:
		camera = player.get_node_or_null("Camera2D")

	# Start cutscene sequence
	await _sequence_earthquake()
	await _sequence_camera_pan()
	_spawn_boss()
	await _sequence_show_text()
	await _sequence_camera_return()

	is_playing = false
	cutscene_finished.emit()

func _sequence_earthquake() -> void:
	print("Cutscene: Earthquake starting...")

	# Shake camera if available
	if camera and camera.has_method("earthquake"):
		camera.earthquake(earthquake_duration)
	elif camera:
		# Manual shake if CameraShake script not attached
		var shake_timer = 0.0
		var shake_intensity = 30.0
		while shake_timer < earthquake_duration:
			camera.offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			await get_tree().create_timer(0.05).timeout
			shake_timer += 0.05
		camera.offset = Vector2.ZERO
	else:
		# No camera, just wait
		await get_tree().create_timer(earthquake_duration).timeout

func _sequence_camera_pan() -> void:
	if camera == null:
		return

	print("Cutscene: Camera panning to boss spawn...")

	# Disable camera following player
	var original_position_smoothing = false
	if camera.has("position_smoothing_enabled"):
		original_position_smoothing = camera.position_smoothing_enabled
		camera.position_smoothing_enabled = false

	# Store original camera position (relative to player)
	var original_offset = camera.offset

	# Calculate world position to pan to
	var target_world_pos = boss_spawn_position
	var camera_target_offset = target_world_pos - player.global_position

	# Tween camera to boss spawn location
	var tween = create_tween()
	tween.tween_property(camera, "offset", camera_target_offset, camera_pan_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	# Store for later return
	camera.set_meta("original_offset", original_offset)
	camera.set_meta("original_smoothing", original_position_smoothing)

func _spawn_boss() -> void:
	if boss_scene == null:
		print("ERROR: Boss scene not set in cutscene!")
		return

	print("Cutscene: Spawning boss...")

	var boss = boss_scene.instantiate()
	get_tree().current_scene.add_child(boss)
	boss.global_position = boss_spawn_position
	boss.add_to_group("enemies")
	boss.add_to_group("bosses")

func _sequence_show_text() -> void:
	print("Cutscene: Showing BOSS BABY text...")

	# Create text label dynamically
	boss_text_label = Label.new()
	boss_text_label.text = "BOSS BABY"
	boss_text_label.add_theme_font_size_override("font_size", 64)
	boss_text_label.modulate = Color(1, 0.2, 0.2, 0)  # Red, start transparent

	# Center on screen
	boss_text_label.anchor_left = 0.5
	boss_text_label.anchor_top = 0.5
	boss_text_label.anchor_right = 0.5
	boss_text_label.anchor_bottom = 0.5
	boss_text_label.grow_horizontal = 2
	boss_text_label.grow_vertical = 2
	boss_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_text_label.offset_left = -200
	boss_text_label.offset_top = -50
	boss_text_label.offset_right = 200
	boss_text_label.offset_bottom = 50

	# Add to UI layer
	var ui_layer = get_tree().get_first_node_in_group("ui_layer")
	if ui_layer == null:
		ui_layer = get_node_or_null("/root/Game/UI")

	if ui_layer:
		ui_layer.add_child(boss_text_label)
	else:
		# Fallback: add to root
		get_tree().current_scene.add_child(boss_text_label)

	# Fade in
	var tween = create_tween()
	tween.tween_property(boss_text_label, "modulate:a", 1.0, 0.5)
	await tween.finished

	# Hold
	await get_tree().create_timer(text_display_duration).timeout

	# Fade out
	tween = create_tween()
	tween.tween_property(boss_text_label, "modulate:a", 0.0, 0.5)
	await tween.finished

	# Remove
	boss_text_label.queue_free()

func _sequence_camera_return() -> void:
	if camera == null:
		return

	print("Cutscene: Returning camera to player...")

	# Get stored values
	var original_offset = camera.get_meta("original_offset", Vector2.ZERO)
	var original_smoothing = camera.get_meta("original_smoothing", true)

	# Tween camera back to player
	var tween = create_tween()
	tween.tween_property(camera, "offset", original_offset, camera_pan_duration * 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	# Re-enable smoothing
	if camera.has("position_smoothing_enabled"):
		camera.position_smoothing_enabled = original_smoothing

	print("Cutscene: Complete!")
