extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
@onready var anim: AnimatedSprite2D = null  # we'll assign in _ready

@export var health: float = 200.0

var throw_timer := 0.0
var normal_speed := 25.0

var is_throwing := false
var throw_duration := 0.5
var throw_time_left := 0.0

var is_hit := false
var hit_duration := 0.2
var hit_time_left := 0.0

var push_timer := 0.0

const projectile_scene := preload("res://scene/Bosses/BossDaddy/BeerBottle.tscn")


func _ready() -> void:
	randomize()
	throw_timer = randf_range(1.0, 4.0)

	# Try common node names: "AnimatedSprite2D" OR "animation"
	anim = get_node_or_null("AnimatedSprite2D")
	if anim == null:
		anim = get_node_or_null("animation")

	if anim != null:
		anim.play("daddy_walk_right")
	else:
		push_warning("BossDaddy: no AnimatedSprite2D child named 'AnimatedSprite2D' or 'animation'.")


func _physics_process(delta: float) -> void:
	throw_timer -= delta
	var direction := global_position.direction_to(player.global_position)

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

	# --- start a new throw if ready (only if not hit or already throwing) ---
	if not is_hit and not is_throwing and throw_timer <= 0.0:
		is_throwing = true
		throw_time_left = throw_duration
		throw_timer = randf_range(1.0, 4.0)

		# shoot once at the start
		shoot()

	# --- movement ---
	if is_hit or is_throwing:
		velocity = Vector2.ZERO
	else:
		velocity = direction * normal_speed

	move_and_slide()

	# push player back if in contact timer
	if push_timer > 0.0:
		push_timer = max(0.0, push_timer - delta)
		player.move_and_collide(8 * player.move_speed * direction * delta)

	# --- animation state machine ---
	if anim == null:
		return  # no sprite node, skip animation

	if is_hit:
		if anim.animation != "daddy_hit":
			anim.play("daddy_hit")
	elif is_throwing:
		if anim.animation != "daddy_attack":
			anim.play("daddy_attack")
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

	if health <= 0.0:
		print("Boss Daddy defeated!")
		_play_death_sound()
		queue_free()
		return

	# Play hit sound
	_play_hit_sound()

	is_hit = true
	hit_time_left = hit_duration

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
