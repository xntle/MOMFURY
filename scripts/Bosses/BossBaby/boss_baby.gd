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

var is_summoning := false
var summon_timer := 0.0
var summon_duration := 1.5          # how long the summon "state" lasts (short = one cast)
var summon_cooldown_duration := 6.0 # cooldown after summoning
var did_summon_this_cast := false


@export var radius := 200.0
@export var count := 5
@export var projectile_scene: PackedScene
@export var summon_scene: PackedScene

func _ready():
	ability_timer = randf_range(1.0, 4.0) 
	
	 

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)

	$animation.play("default")
	# SHOOTING MODE
	if is_throwing:
		shoot_timer -= delta
		shoot_interval_timer -= delta

		# enemy stops moving
		velocity = Vector2.ZERO

		# fire at constant interval
		if shoot_interval_timer <= 0:
			shoot()
			shoot_interval_timer = shoot_interval

		# end shooting phase
		if shoot_timer <= 0:
			is_throwing = false
			cooldown_timer = cooldown_duration
	elif is_summoning:
		summon_timer -= delta
		velocity = Vector2.ZERO

		if !did_summon_this_cast:
			$Summoner.summon()
			did_summon_this_cast = true

		if summon_timer <= 0.0:
			is_summoning = false
			cooldown_timer = summon_cooldown_duration
		
	# MOVEMENT MODE
	else:
		cooldown_timer -= delta
		velocity = direction * normal_speed

		if cooldown_timer <= 0:
			var random_ability = randi_range(1, 2)
			if random_ability == 1:
				is_throwing = true
				shoot_timer = shoot_duration
				shoot_interval_timer = 0.0  # fire immediately when entering shooting mode
			else:
				is_summoning = true
				summon_timer = summon_duration
				did_summon_this_cast = false
			
	# move enemy
	move_and_slide()
	if push_timer > 0.0:
		push_timer = max(0,push_timer-delta)
		player.move_and_collide(8 * player.move_speed * direction * delta)

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


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2 # Replace with function body.
