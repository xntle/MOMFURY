extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var ability_timer := 0.0
var throw_speed := 250.0
var normal_speed := 25.0
var is_throwing := false
var throw_duration := 0.2
var throw_time_left := 0.0

var shoot_timer = 0.0
var cooldown_timer = 0.0
var shoot_duration = 3.0       # shoot for 5 seconds
var cooldown_duration = 5.0    # wait 5 seconds before shooting again
var push_timer = 0.0

var shoot_interval = 1.0   
var shoot_interval_timer = 0.0

var beam: Node2D = null  
@export var max_health: float = 2000.0
var health:float = max_health

const projectile_scene := preload("res://scene/Bosses/BossTeen/ScreamAttack.tscn")
@export var turn_speed: float = 6.0 # radians/sec (smaller = more lag)
signal health_changed(new_health:int)

func _ready():
	ability_timer = randf_range(1.0, 4.0) 
	var health_bar = get_tree().current_scene.get_node("UI/BossHealthBar")
	health_bar.connect_boss(self)

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)

	$animation.play("default")
	# SHOOTING MODE
	if is_throwing:
		velocity = Vector2.ZERO
		shoot_timer -= delta

		# spawn beam ONCE at start of attack
		if beam == null or not is_instance_valid(beam):
			beam = spawn_beam()

		# keep beam attached to boss (optional but usually desired)
		if is_instance_valid(beam):
			beam.global_position = global_position

		if is_instance_valid(player):
			var target_angle = (player.global_position - global_position).angle()
			rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
			
		# end attack after 4 seconds
		if shoot_timer <= 0.0:
			end_beam_attack()
	# MOVEMENT MODE
	else:
		rotation = 0.0
		cooldown_timer -= delta
		velocity = direction * normal_speed

		if cooldown_timer <= 0:
			is_throwing = true
			shoot_timer = shoot_duration
			shoot_interval_timer = 0.0  # fire immediately when entering shooting mode
			
			
	# move enemy
	move_and_slide()
	if push_timer > 0.0:
		push_timer = max(0,push_timer-delta)
		player.move_and_collide(8 * player.move_speed * direction * delta)

func start_beam_attack() -> void:
	is_throwing = true
	shoot_timer = shoot_duration
	# beam will spawn on next _physics_process frame (or you can spawn here)

func end_beam_attack() -> void:
	is_throwing = false
	cooldown_timer = cooldown_duration

	if is_instance_valid(beam):
		beam.queue_free()
	beam = null

func spawn_beam() -> Node2D:
	if projectile_scene == null:
		return null

	var b := projectile_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	return b


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2 # Replace with function body.

# Damage function
func take_damage(amount: float) -> void:
	health -= amount
	print("Boss Daddy took ", amount, " damage. Health: ", health)
	emit_signal("health_changed", health)

	if health <= 0:
		print("Boss Daddy defeated!")
		_play_death_sound()
		queue_free()
		return

	# Play hit sound
	_play_hit_sound()


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
