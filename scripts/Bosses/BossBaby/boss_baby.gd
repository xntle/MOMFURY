extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
@onready var agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim: AnimatedSprite2D

@export var max_health: float = 2000.0
var health: float = max_health

var ability_timer := 0.0
var throw_speed := 250.0
var normal_speed := 40.0

var is_throwing := false
var throw_duration := 0.2
var throw_time_left := 0.0

var shoot_timer := 0.0
var cooldown_timer := 0.0
var shoot_duration := 3.0
var cooldown_duration := 5.0
var push_timer := 0.0

var shoot_interval := 1.0
var shoot_interval_timer := 0.0

var is_summoning := false
var summon_timer := 0.0
var summon_duration := 1.5
var summon_cooldown_duration := 6.0
var did_summon_this_cast := false

# hit reaction
var is_hit := false
var hit_duration := 0.4
var hit_timer := 0.0

signal health_changed(new_health: int)

@export var radius := 200.0
@export var count := 5
const projectile_scene := preload("res://scene/Bosses/BossBaby/CryAttack.tscn")
@export var summon_scene: PackedScene

func _ready() -> void:
	randomize()
	ability_timer = randf_range(1.0, 4.0)

	var health_bar = get_tree().current_scene.get_node("UI/BossHealthBar")
	health_bar.connect_boss(self)

	anim = get_node_or_null("AnimatedSprite2D")
	if anim == null:
		anim = get_node_or_null("animation")

	# ---- NAV TUNING (adjust to boss size) ----
	if agent != null:
		agent.target_desired_distance = 8.0
		agent.radius = 16.0
	# -----------------------------------------

	if anim != null:
		anim.play("default_walk")
	else:
		push_warning("BossBaby: no AnimatedSprite2D child named 'AnimatedSprite2D' or 'animation'.")

func take_damage(amount: float) -> void:
	health -= amount
	print("BossBaby took ", amount, " damage. HP: ", health)
	emit_signal("health_changed", health)

	if health <= 0.0:
		_play_death_sound()
		_trigger_death_screen_shake()
		queue_free()
		return

	# Play hit sound and flash when hit
	_play_hit_sound()
	_flash_white()

	if is_hit:
		return

	is_hit = true
	hit_timer = hit_duration

	# interrupt abilities
	is_throwing = false
	is_summoning = false

	if anim:
		anim.play("baby_hit")

func _get_nav_direction() -> Vector2:
	# Update target
	if agent != null and is_instance_valid(player):
		agent.target_position = player.global_position

	# If we have a path, follow it
	if agent != null and not agent.is_navigation_finished():
		var next_pos := agent.get_next_path_position()
		var v := next_pos - global_position
		if v.length() > 0.001:
			return v.normalized()

	# Fallback direct
	if is_instance_valid(player):
		return (player.global_position - global_position).normalized()

	return Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var move_dir := _get_nav_direction()

	# -------------------------
	# HIT OVERRIDE
	# -------------------------
	if is_hit:
		hit_timer -= delta

		# baby still moves while hit (now using nav direction)
		velocity = move_dir * normal_speed
		move_and_slide()

		if push_timer > 0.0:
			push_timer = max(0.0, push_timer - delta)
			player.move_and_collide(8 * player.move_speed * move_dir * delta)

		if hit_timer <= 0.0:
			is_hit = false

		if anim and anim.animation != "baby_hit":
			anim.play("baby_hit")

		return

	# -------------------------
	# ABILITY / STATE LOGIC
	# -------------------------

	if is_throwing:
		shoot_timer -= delta
		shoot_interval_timer -= delta

		if shoot_interval_timer <= 0.0:
			shoot()
			shoot_interval_timer = shoot_interval

		if shoot_timer <= 0.0:
			is_throwing = false
			cooldown_timer = cooldown_duration

	elif is_summoning:
		summon_timer -= delta

		if not did_summon_this_cast:
			_do_summon()
			did_summon_this_cast = true

		if summon_timer <= 0.0:
			is_summoning = false
			cooldown_timer = summon_cooldown_duration

	else:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			var random_ability := randi_range(1, 2) # (your code always chooses 1)
			if random_ability == 1:
				is_throwing = true
				shoot_timer = shoot_duration
				shoot_interval_timer = 0.0
			else:
				is_summoning = true
				summon_timer = summon_duration
				did_summon_this_cast = false

	# -------------------------
	# MOVEMENT (pathfinding)
	# -------------------------
	velocity = move_dir * normal_speed
	move_and_slide()

	if push_timer > 0.0:
		push_timer = max(0.0, push_timer - delta)
		player.move_and_collide(8 * player.move_speed * move_dir * delta)

	# -------------------------
	# FACING DIRECTION
	# -------------------------
	if anim != null:
		if move_dir.x < 0:
			anim.flip_h = true  # Face left
		elif move_dir.x > 0:
			anim.flip_h = false  # Face right

	# -------------------------
	# ANIMATION
	# -------------------------
	if not anim:
		return

	var desired_anim := "baby_throw_diaper" if (is_throwing or is_summoning) else "default_walk"
	if not is_hit and anim.animation != desired_anim:
		anim.play(desired_anim)

func shoot() -> void:
	if projectile_scene == null:
		return

	var directions = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN,
		Vector2(1, 1).normalized(),
		Vector2(1, -1).normalized(),
		Vector2(-1, 1).normalized(),
		Vector2(-1, -1).normalized()
	]

	for dir in directions:
		var projectile = projectile_scene.instantiate()
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		projectile.direction = dir

func _do_summon() -> void:
	if summon_scene == null:
		return

	for i in count:
		var angle := TAU * float(i) / float(count)
		var offset := Vector2(cos(angle), sin(angle)) * radius

		var minion = summon_scene.instantiate()
		get_tree().current_scene.add_child(minion)
		minion.global_position = global_position + offset

func _play_death_sound() -> void:
	# (unchanged)
	var death_sounds = [
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-001.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-002.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-003.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-004.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-005.wav",
		"res://assets/sound/Death/DSGNImpt_EXPLOSION-Mecha Piercing Punch_HY_PC-006.wav"
	]
	var random_sound_path = death_sounds[randi() % death_sounds.size()]
	var sound = load(random_sound_path) as AudioStream
	if sound != null:
		var audio_player = AudioStreamPlayer2D.new()
		get_tree().current_scene.add_child(audio_player)
		audio_player.stream = sound
		audio_player.global_position = global_position
		if sound is AudioStreamWAV:
			sound.loop_mode = AudioStreamWAV.LOOP_DISABLED
		audio_player.play()
		get_tree().create_timer(3.0).timeout.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)
		audio_player.finished.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)

func _play_hit_sound() -> void:
	# (unchanged)
	var hit_sound = load("res://assets/sound/Hit/Hit.wav") as AudioStream
	if hit_sound != null:
		var audio_player = AudioStreamPlayer2D.new()
		get_tree().current_scene.add_child(audio_player)
		audio_player.stream = hit_sound
		audio_player.global_position = global_position
		if hit_sound is AudioStreamWAV:
			hit_sound.loop_mode = AudioStreamWAV.LOOP_DISABLED
		audio_player.play()
		get_tree().create_timer(2.0).timeout.connect(func():
			if is_instance_valid(audio_player):
				audio_player.queue_free()
		)
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


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2


func _spawn_hit_effect() -> void:
	var hit_effect_path = "res://scene/Effects/HitImpact.tscn"
	var hit_scene = load(hit_effect_path) as PackedScene

	if hit_scene != null:
		var hit_effect = hit_scene.instantiate()
		get_tree().current_scene.add_child(hit_effect)
		hit_effect.global_position = global_position
