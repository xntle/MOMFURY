extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var throw_timer := 0.0
var throw_speed := 250.0
var normal_speed := 25.0
var is_throwing := false
var throw_duration := 0.2
var throw_time_left := 0.0

@export var projectile_scene: PackedScene


func _ready():
	# First random cooldown 1 to 3 seconds
	throw_timer = randf_range(1.0, 3.0)  

func _physics_process(delta):
	throw_timer -= delta

	var direction = global_position.direction_to(player.global_position)

	# Start a throw when timer hits zero
	if throw_timer <= 0.0:
		is_throwing = true
		throw_timer = randf_range(1.0, 3.0)  
		

	# Dash or normal move
	if is_throwing:
		#velocity = direction * throw_speed
		shoot()
		is_throwing = false
	velocity = direction * normal_speed

	move_and_slide()
	rotation = direction.angle() +90

func shoot() -> void:
	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)  # or get_parent(), depending on structure

	# Set initial position (e.g. player position or a gun muzzle position)
	projectile.global_position = global_position

	# Choose direction: here, facing right or using input/aim direction
	projectile.direction = (player.global_position - global_position).normalized()
