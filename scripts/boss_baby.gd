extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var throw_timer := 0.0
var throw_speed := 250.0
var normal_speed := 25.0
var is_throwing := false
var throw_duration := 0.2
var throw_time_left := 0.0

var shoot_timer = 0.0
var cooldown_timer = 0.0
var shoot_duration = 3.0       # shoot for 5 seconds
var cooldown_duration = 5.0    # wait 5 seconds before shooting again


var shoot_interval = 1.0   
var shoot_interval_timer = 0.0

@export var projectile_scene: PackedScene

func _ready():
	# First random cooldown 1 to 3 seconds
	throw_timer = randf_range(1.0, 4.0)  

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

	# MOVEMENT MODE
	else:
		cooldown_timer -= delta
		velocity = direction * normal_speed

		if cooldown_timer <= 0:
			is_throwing = true
			shoot_timer = shoot_duration
			shoot_interval_timer = 0.0  # fire immediately when entering shooting mode

	# move enemy
	move_and_slide()




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
