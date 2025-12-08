extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
@onready var anim: AnimatedSprite2D = $animation

var normal_speed := 80.0
var stop_distance := 200.0  # Stay further back to shoot
var shoot_range := 250.0     # Max shooting distance

@export var health := 20.0
@export var bullet_scene: PackedScene
@export var health_pickup_scene: PackedScene
@export var drop_chance: float = 0.3  # 30% chance
@export var death_particles_scene: PackedScene
@onready var agent: NavigationAgent2D = $NavigationAgent2D


# Shooting
var shoot_cooldown := 0.8
var shoot_timer := 0.0
var bullets_per_burst := 3
var burst_delay := 0.15

func _ready() -> void:
	agent.path_desired_distance = 8.0
	agent.target_desired_distance = stop_distance

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var distance_to_player := global_position.distance_to(player.global_position)
	var direction := global_position.direction_to(player.global_position)

	# Update shoot timer
	if shoot_timer > 0.0:
		shoot_timer -= delta

	# Update path target (you can do this every frame, or via your Timer)
	agent.target_position = player.global_position

	# Update facing direction based on player position
	var sprite = get_node_or_null("animation")
	if sprite != null:
		if direction.x < 0:
			sprite.flip_h = true  # Face left
		elif direction.x > 0:
			sprite.flip_h = false  # Face right

	# Move using navigation path
	if distance_to_player > stop_distance:
		var next_pos := agent.get_next_path_position()
		var dir := (next_pos - global_position).normalized()
		velocity = dir * normal_speed
	else:
		velocity = Vector2.ZERO

		if distance_to_player <= shoot_range and shoot_timer <= 0.0 and bullet_scene != null:
			_shoot_burst()
			shoot_timer = shoot_cooldown

	move_and_slide()


func _shoot_burst():
	for i in bullets_per_burst:
		# Check if tree is valid
		if get_tree() == null or not is_instance_valid(self):
			return

		await get_tree().create_timer(i * burst_delay).timeout

		# Check again after await
		if not is_instance_valid(self):
			return

		_shoot_bullet()
	
	if anim:
		anim.play("default") 


func _shoot_bullet():
	if bullet_scene == null or player == null:
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position

	# Aim at player with slight spread
	var spread = randf_range(-0.1, 0.1)
	var direction = global_position.direction_to(player.global_position).rotated(spread)
	bullet.direction = direction
	
func _on_timer_timeout():
	if $NavigationAgent2D.target_position != player.global_position:
		$NavigationAgent2D.target_position = player.global_position
	$Timer.start()
	
	
func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		print("Poop defeated!")
		_drop_health()
		_spawn_death_particles()
		_trigger_death_screen_shake()
		queue_free()
		if is_instance_valid(player) and player.has_method("add_points"):
			player.add_points(10)
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
		"res://assets/Sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-001.wav",
		"res://assets/Sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-002.wav",
		"res://assets/Sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-003.wav",
		"res://assets/Sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-004.wav",
		"res://assets/Sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-005.wav",
		"res://assets/Sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-006.wav"
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
	var hit_sound = load("res://assets/Sound/Hit/Hit.wav") as AudioStream

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
	var sprite = get_node_or_null("animation")
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


func _spawn_hit_effect() -> void:
	var hit_effect_path = "res://scene/Effects/HitImpact.tscn"
	var hit_scene = load(hit_effect_path) as PackedScene

	if hit_scene != null:
		var hit_effect = hit_scene.instantiate()
		get_tree().current_scene.add_child(hit_effect)
		hit_effect.global_position = global_position
