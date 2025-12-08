extends CharacterBody2D

@onready var player: CharacterBody2D = get_node("/root/Game/Player")

@export var health: float = 10.0
@export var speed: float = 100.0
@export var damage: float = 25.0
@export var health_pickup_scene: PackedScene
@export var drop_chance: float = 0.2  # 20% chance
@export var death_particles_scene: PackedScene
@onready var agent: NavigationAgent2D = $NavigationAgent2D


var dash_timer: float = 0.0
var dash_speed: float = 250.0
var is_dashing: bool = false
var dash_duration: float = 0.2
var dash_time_left: float = 0.0
var bounce_timer: float = 0.0
var default_bounce_timer: float = 0.25


func _ready():
	dash_timer = randf_range(1.0, 3.0)
	agent.target_position = player.global_position

func _physics_process(delta):
	bounce_timer = max(0.0, bounce_timer - delta)
	dash_timer = max(0.0, dash_timer - delta)

	if not is_instance_valid(player):
		return

	# update nav target (or keep your Timer method instead)
	agent.target_position = player.global_position

	var to_player := player.global_position - global_position
	var direct_dir := to_player.normalized()

	# Start a dash when timer hits zero
	if dash_timer <= 0.0:
		is_dashing = true
		dash_time_left = dash_duration
		dash_timer = randf_range(1.0, 3.0)

	# Dash or normal move or bounce
	if is_dashing:
		var dash_dir: Vector2

		if not agent.is_navigation_finished():
			var next_pos := agent.get_next_path_position()
			dash_dir = (next_pos - global_position).normalized()
		else:
			dash_dir = direct_dir  # fallback if no path

		velocity = dash_dir * dash_speed
		dash_time_left -= delta
		if dash_time_left <= 0.0:
			is_dashing = false

	elif bounce_timer >= 0.1:
		velocity = -4.0 * direct_dir * speed

	else:
		# NORMAL MOVE USING NAVIGATION PATH
		if not agent.is_navigation_finished():
			var next_pos := agent.get_next_path_position()
			var nav_dir := (next_pos - global_position).normalized()
			velocity = nav_dir * speed
		else:
			velocity = direct_dir * speed

	# stands still for warning window before dash
	if not (dash_timer > 0.0 and dash_timer <= 0.5):
		move_and_slide()

	rotation = direct_dir.angle() + deg_to_rad(90)
	
func _on_timer_timeout():
	if $NavigationAgent2D.target_position != player.global_position:
		$NavigationAgent2D.target_position = player.global_position
	$Timer.start()
	
func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		_drop_health()
		_spawn_death_particles()
		_trigger_death_screen_shake()
		queue_free()
		if is_instance_valid(player) and player.has_method("add_points"):
			player.add_points(5)
	else:
		# Play hit sound and flash when hit
		_play_hit_sound()
		_flash_white()


func _drop_health() -> void:
	# 50% chance to drop health
	if randf() < drop_chance and health_pickup_scene != null:
		var health_drop = health_pickup_scene.instantiate()
		get_tree().current_scene.add_child(health_drop)
		health_drop.global_position = global_position


func _spawn_death_particles() -> void:
	if death_particles_scene != null:
		var particles = death_particles_scene.instantiate()
		get_tree().current_scene.add_child(particles)
		particles.global_position = global_position

	# Spawn soul escape effect
	var soul_scene = load("res://scene/Effects/SoulEscape.tscn")
	if soul_scene != null:
		var soul = soul_scene.instantiate()
		get_tree().current_scene.add_child(soul)
		soul.global_position = global_position

	# Play random death sound
	_play_death_sound()


func _play_death_sound() -> void:
	# Array of death sound paths
	var death_sounds = [
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-001.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-002.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-003.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-004.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-005.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-006.wav"
	]

	# Pick random sound and play it
	var random_sound_path = death_sounds[randi() % death_sounds.size()]
	var sound = load(random_sound_path) as AudioStream

	if sound != null:
		var audio_player = AudioStreamPlayer2D.new()
		get_tree().current_scene.add_child(audio_player)
		audio_player.stream = sound
		audio_player.global_position = global_position

		# Ensure sound doesn't loop
		if sound is AudioStreamWAV:
			sound.loop_mode = AudioStreamWAV.LOOP_DISABLED

		audio_player.play()

		# Auto-cleanup after 3 seconds max (in case finished signal doesn't fire)
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

		# Also cleanup when finished normally
		audio_player.finished.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)


func _play_hit_sound() -> void:
	var hit_sound = load("res://assets/sound/Hit/Hit.wav") as AudioStream

	if hit_sound != null:
		var audio_player = AudioStreamPlayer2D.new()
		get_tree().current_scene.add_child(audio_player)
		audio_player.stream = hit_sound
		audio_player.global_position = global_position

		# Ensure sound doesn't loop
		if hit_sound is AudioStreamWAV:
			hit_sound.loop_mode = AudioStreamWAV.LOOP_DISABLED

		audio_player.play()

		# Auto-cleanup after 2 seconds max
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

		# Also cleanup when finished normally
		audio_player.finished.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)


func _flash_white() -> void:
	var sprite = get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		return

	# Flash white
	sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)

	# Check if tree is valid
	if get_tree() == null:
		return

	await get_tree().create_timer(0.1).timeout

	# Return to normal color if still valid
	if is_instance_valid(sprite):
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _trigger_death_screen_shake() -> void:
	# Find the camera (attached to player)
	if player == null:
		return

	var camera = player.get_node_or_null("Camera2D")
	if camera != null and camera.has_method("shake"):
		camera.shake(8.0, 0.3)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(damage)
		bounce_timer+=default_bounce_timer
		is_dashing = false
		dash_timer = randf_range(1.0, 3.0)  
