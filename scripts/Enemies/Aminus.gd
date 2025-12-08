extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var normal_speed := 40.0
var stop_distance := 200.0  # Stay much further back to shoot
var shoot_range := 250.0    # Long range shooter

@export var health := 85.0
@export var bullet_scene: PackedScene
@export var health_pickup_scene: PackedScene
@export var drop_chance: float = 0.5  # 50% chance
@export var death_particles_scene: PackedScene

# Shooting
var shoot_cooldown := 1.5
var shoot_timer := 0.0


func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	var distance_to_player = global_position.distance_to(player.global_position)

	# Update shoot timer
	if shoot_timer > 0:
		shoot_timer -= delta

	# Move toward player ONLY if farther than stop distance
	if distance_to_player > stop_distance:
		velocity = direction * normal_speed
	else:
		velocity = Vector2.ZERO

		# Shoot at player when in range
		if distance_to_player <= shoot_range and shoot_timer <= 0 and bullet_scene != null:
			_shoot_bullet()
			shoot_timer = shoot_cooldown

	move_and_slide()


func _shoot_bullet():
	if bullet_scene == null or player == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	# Aim directly at player
	var direction = global_position.direction_to(player.global_position)
	bullet.direction = direction
	
func _on_timer_timeout():
	if $NavigationAgent2D.target_position != player.global_position:
		$NavigationAgent2D.target_position = player.global_position
	$Timer.start()
	
	
func take_damage(amount: float) -> void:
	health -= amount
	print("A- took ", amount, " damage. Health: ", health)

	if health <= 0:
		print("A- defeated!")
		_drop_health()
		_spawn_death_particles()
		queue_free()
		if is_instance_valid(player) and player.has_method("add_points"):
			player.add_points(20)
	else:
		# Play hit sound only if still alive
		_play_hit_sound()


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
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Cruncher_HY_PC.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Crunchy Burst_HY_PC.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Engine Burst_HY_PC.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Limb Explosion_HY_PC.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Thud_HY_PC.wav",
		"res://assets/sound/Death/DSGNMisc_HIT-Mecha Armor Piercer_HY_PC.wav"
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
