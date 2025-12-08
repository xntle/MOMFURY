extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
@onready var anim: AnimatedSprite2D = null  # we'll assign in _ready
@onready var agent: NavigationAgent2D = $NavigationAgent2D

@export var max_health: float = 2000.0
var health: float = max_health


var throw_timer := 0.0
var normal_speed := 60.0

var is_throwing := false
var throw_duration := 0.5
var throw_time_left := 0.0

var is_hit := false
var hit_duration := 0.2
var hit_time_left := 0.0

var push_timer := 0.0

const projectile_scene := preload("res://scene/Bosses/BossDaddy/BeerBottle.tscn")

signal health_changed(new_health:int)


func _ready() -> void:
	randomize()
	throw_timer = randf_range(1.0, 4.0)

	# boss health UI hookup
	var health_bar = get_tree().current_scene.get_node("UI/BossHealthBar")
	health_bar.connect_boss(self)

	anim = get_node_or_null("AnimatedSprite2D")
	if anim == null:
		anim = get_node_or_null("animation")

	# nav tuning (adjust to your boss size)
	agent.path_desired_distance = 12.0
	agent.target_desired_distance = 8.0
	agent.radius = 16.0

	if anim != null:
		anim.play("daddy_walk_right")
	else:
		push_warning("BossDaddy: no AnimatedSprite2D child named 'AnimatedSprite2D' or 'animation'.")

func _physics_process(delta: float) -> void:
	throw_timer -= delta

	if not is_instance_valid(player):
		return

	# keep target updated
	agent.target_position = player.global_position

	var to_player = player.global_position - global_position
	var direction_to_player = to_player.normalized()

	# --- update hit timer ---
	if is_hit:
		hit_time_left -= delta
		if hit_time_left <= 0.0:
			is_hit = false

	# --- update throw timer ---
	if is_throwing:
		throw_time_left -= delta
		if throw_time_left <= 0.0:
			is_throwing = false

	# --- start a new throw if ready ---
	var dist_to_player := global_position.distance_to(player.global_position)

	if not is_throwing and throw_timer <= 0.0 and dist_to_player < 200.0:
		is_throwing = true
		throw_time_left = throw_duration
		throw_timer = randf_range(1.0, 4.0)
		shoot()

	# --- movement using pathfinding ---
	if is_throwing:
		velocity = Vector2.ZERO
	else:
		if not agent.is_navigation_finished():
			var next_pos := agent.get_next_path_position()
			var nav_dir := (next_pos - global_position).normalized()
			velocity = nav_dir * normal_speed
		else:
			velocity = direction_to_player * normal_speed

	move_and_slide()

	# push player back if in contact timer
	if push_timer > 0.0:
		push_timer = max(0.0, push_timer - delta)
		player.move_and_collide(8 * player.move_speed * direction_to_player * delta)

	# --- animation state machine ---
	if anim == null:
		return

	# Update facing direction based on player position
	if direction_to_player.x < 0:
		anim.flip_h = true  # Face left
	elif direction_to_player.x > 0:
		anim.flip_h = false  # Face right

	if is_hit:
		if anim.animation != "daddy_hit":
			anim.play("daddy_hit")
	elif is_throwing:
		if anim.animation != "daddy_attack":
			anim.play("daddy_attack")
	elif is_hit:
		if anim.animation != "daddy_hit":
			anim.play("daddy_hit")
	else:
		if anim.animation != "daddy_walk_right":
			anim.play("daddy_walk_right")

func shoot() -> void:
	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2


func take_damage(amount: float) -> void:
	health -= amount
	print("Boss Daddy took ", amount, " damage. Health: ", health)
	emit_signal("health_changed", health)

	if health <= 0.0:
		print("Boss Daddy defeated!")
		_play_death_sound()
		_trigger_death_screen_shake()
		queue_free()
		return

	# Play hit sound and flash when hit
	_play_hit_sound()
	_flash_white()

	is_hit = true
	hit_time_left = hit_duration

	# Interrupt throwing when hit
	is_throwing = false

	if anim != null:
		anim.play("daddy_hit")


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
	if anim == null:
		return

	# Flash white
	anim.modulate = Color(2.0, 2.0, 2.0, 1.0)

	# Check if tree is valid
	if get_tree() == null:
		return

	await get_tree().create_timer(0.1).timeout

	# Return to normal color if still valid
	if is_instance_valid(anim):
		anim.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _trigger_death_screen_shake() -> void:
	# Find the camera (attached to player)
	if player == null:
		return

	var camera = player.get_node_or_null("Camera2D")
	if camera != null and camera.has_method("shake"):
		camera.shake(10.0, 0.4)
