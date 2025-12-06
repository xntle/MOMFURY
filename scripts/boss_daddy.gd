extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

@export var health: float = 200.0

var throw_timer := 0.0
var throw_speed := 250.0
var normal_speed := 25.0
var is_throwing := false
var throw_duration := 0.2
var throw_time_left := 0.0
var push_timer: = 0.0

const projectile_scene := preload("res://scene/BeerBottle.tscn") 

func _ready():
	# First random cooldown 1 to 3 seconds
	throw_timer = randf_range(1.0, 4.0)  

func _physics_process(delta):
	throw_timer -= delta

	var direction = global_position.direction_to(player.global_position)

	# Start a throw when timer hits zero
	if throw_timer <= 0.0:
		is_throwing = true
		throw_timer = randf_range(1.0, 10.0)  
		

	# Dash or normal move
	if is_throwing:
		#velocity = direction * throw_speed
		shoot()
		is_throwing = false
	velocity = direction * normal_speed

	move_and_slide()
	if push_timer > 0.0:
		push_timer = max(0,push_timer-delta)
		player.move_and_collide(8 * player.move_speed * direction * delta)
	#rotation = direction.angle() +90

func shoot() -> void:
	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)  # or get_parent(), depending on structure

	# Set initial position (e.g. player position or a gun muzzle position)
	projectile.global_position = global_position

	# Choose direction: here, facing right or using input/aim direction
	projectile.direction = (player.global_position - global_position).normalized()
	


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2

# Damage function
func take_damage(amount: float) -> void:
	health -= amount
	print("Boss Daddy took ", amount, " damage. Health: ", health)

	if health <= 0:
		print("Boss Daddy defeated!")
		queue_free()
