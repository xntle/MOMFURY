#extends CharacterBody2D
#
#@onready var player = get_node("/root/Game/Player")
#
#var ability_timer := 0.0
#var throw_speed := 250.0
#var normal_speed := 25.0
#var is_throwing := false
#var throw_duration := 0.2
#var throw_time_left := 0.0
#
#var shoot_timer = 0.0
#var cooldown_timer = 0.0
#var shoot_duration = 3.0       # shoot for 5 seconds
#var cooldown_duration = 5.0    # wait 5 seconds before shooting again
#var push_timer = 0.0
#
#var shoot_interval = 1.0   
#var shoot_interval_timer = 0.0
#
#var is_summoning := false
#var summon_timer := 0.0
#var summon_duration := 1.5          # how long the summon "state" lasts (short = one cast)
#var summon_cooldown_duration := 6.0 # cooldown after summoning
#var did_summon_this_cast := false
#
#
#@export var radius := 200.0
#@export var count := 5
#@export var projectile_scene: PackedScene
#@export var summon_scene: PackedScene
#
#func _ready():
	#ability_timer = randf_range(1.0, 4.0) 
	#
	 #
#
#func _physics_process(delta):
	#var direction = global_position.direction_to(player.global_position)
#
	#$animation.play("default")
	## SHOOTING MODE
	#if is_throwing:
		#shoot_timer -= delta
		#shoot_interval_timer -= delta
#
		## enemy stops moving
		#velocity = Vector2.ZERO
#
		## fire at constant interval
		#if shoot_interval_timer <= 0:
			#shoot()
			#shoot_interval_timer = shoot_interval
#
		## end shooting phase
		#if shoot_timer <= 0:
			#is_throwing = false
			#cooldown_timer = cooldown_duration
	#elif is_summoning:
		#summon_timer -= delta
		#velocity = Vector2.ZERO
#
		#if !did_summon_this_cast:
			##$Summoner.summon()
			#_do_summon()
			#did_summon_this_cast = true
#
		#if summon_timer <= 0.0:
			#is_summoning = false
			#cooldown_timer = summon_cooldown_duration
		#
	## MOVEMENT MODE
	#else:
		#cooldown_timer -= delta
		#velocity = direction * normal_speed
#
		#if cooldown_timer <= 0:
			#var random_ability = randi_range(1, 2)
			#if random_ability == 1:
				#is_throwing = true
				#shoot_timer = shoot_duration
				#shoot_interval_timer = 0.0  # fire immediately when entering shooting mode
			#else:
				#is_summoning = true
				#summon_timer = summon_duration
				#did_summon_this_cast = false
			#
	## move enemy
	#move_and_slide()
	#if push_timer > 0.0:
		#push_timer = max(0,push_timer-delta)
		#player.move_and_collide(8 * player.move_speed * direction * delta)
#
#func shoot() -> void:
	#if projectile_scene == null:
		#return
#
	#var directions = [
		#Vector2.RIGHT,
		#Vector2.LEFT,
		#Vector2.UP,
		#Vector2.DOWN,
		#Vector2(1, 1).normalized(),
		#Vector2(1, -1).normalized(),
		#Vector2(-1, 1).normalized(),
		#Vector2(-1, -1).normalized()
	#]
#
	#for dir in directions:
		#var projectile = projectile_scene.instantiate()
		#get_tree().current_scene.add_child(projectile)
#
		#projectile.global_position = global_position
		#projectile.direction = dir
#
#func _do_summon():
	#if summon_scene == null:
		#return
#
	#for i in count:
		#var angle = TAU * float(i) / float(count)
		#var offset = Vector2(cos(angle), sin(angle)) * radius
#
		#var minion = summon_scene.instantiate()
		#get_tree().current_scene.add_child(minion)
		#minion.global_position = global_position + offset
#
#
#func _on_area_2d_body_entered(body: Node2D) -> void:
	#if body == player:
		#player.take_damage(15)
		#player.apply_stun(0.2)
		#player.apply_intangibility(0.4)
		#push_timer = 0.2 # Replace with function body.


extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
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
var shoot_duration := 3.0          # shoot for 3 seconds
var cooldown_duration := 5.0       # wait 5 seconds before another ability
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

signal health_changed(new_health:int)

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

	if anim != null:
		anim.play("default_walk")  # always looping base anim
	else:
		push_warning("BossDaddy: no AnimatedSprite2D child named 'AnimatedSprite2D' or 'animation'.")
	

func take_damage(amount: float) -> void:
	health -= amount
	print("BossBaby took ", amount, " damage. HP: ", health)
	emit_signal("health_changed", health)
	if health <= 0.0:
		_play_death_sound()
		queue_free()
		return

	# Play hit sound
	_play_hit_sound()

	# already in hit state? don't restart
	if is_hit:
		return

	is_hit = true
	hit_timer = hit_duration

	# interrupt abilities
	is_throwing = false
	is_summoning = false

	anim.play("baby_hit")


func _physics_process(delta: float) -> void:
	var direction := global_position.direction_to(player.global_position)

	# -------------------------
	# HIT OVERRIDE (highest prio)
	# -------------------------
	if is_hit:
		hit_timer -= delta

		# baby still moves while being hit
		velocity = direction * normal_speed
		move_and_slide()

		if push_timer > 0.0:
			push_timer = max(0.0, push_timer - delta)
			player.move_and_collide(8 * player.move_speed * direction * delta)

		if hit_timer <= 0.0:
			is_hit = false

		# keep hit anim playing during this time
		if anim.animation != "baby_hit":
			anim.play("baby_hit")

		return  # skip abilities while in hit state

	# -------------------------
	# ABILITY / STATE LOGIC
	# -------------------------

	# SHOOTING MODE
	if is_throwing:
		shoot_timer -= delta
		shoot_interval_timer -= delta

		if shoot_interval_timer <= 0.0:
			shoot()
			shoot_interval_timer = shoot_interval

		if shoot_timer <= 0.0:
			is_throwing = false
			cooldown_timer = cooldown_duration

	# SUMMONING MODE
	elif is_summoning:
		summon_timer -= delta

		if not did_summon_this_cast:
			_do_summon()
			did_summon_this_cast = true

		if summon_timer <= 0.0:
			is_summoning = false
			cooldown_timer = summon_cooldown_duration

	# MOVEMENT / COOLDOWN MODE
	else:
		cooldown_timer -= delta

		if cooldown_timer <= 0.0:
			var random_ability := randi_range(1, 1)
			if random_ability == 1:
				is_throwing = true
				shoot_timer = shoot_duration
				shoot_interval_timer = 0.0  # fire immediately
			else:
				is_summoning = true
				summon_timer = summon_duration
				did_summon_this_cast = false

	# -------------------------
	# MOVEMENT (always moving)
	# -------------------------
	velocity = direction * normal_speed
	move_and_slide()

	if push_timer > 0.0:
		push_timer = max(0.0, push_timer - delta)
		player.move_and_collide(8 * player.move_speed * direction * delta)

	# -------------------------
	# ANIMATION
	# -------------------------
	var desired_anim := ""

	if is_throwing or is_summoning:
		desired_anim = "baby_throw_diaper"
	else:
		desired_anim = "default_walk"

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


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2
