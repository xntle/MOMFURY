extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var normal_speed := 40.0
var stop_distance := 120.0  # Stay further back to shoot
var shoot_range := 150.0     # Max shooting distance

@export var health := 25.0
@export var bullet_scene: PackedScene
@export var health_pickup_scene: PackedScene
@export var drop_chance: float = 0.5  # 50% chance
@export var death_particles_scene: PackedScene

# Shooting
var shoot_cooldown := 2.0
var shoot_timer := 0.0
var bullets_per_burst := 3
var burst_delay := 0.15

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	var distance_to_player = global_position.distance_to(player.global_position)

	# Update shoot timer
	if shoot_timer > 0:
		shoot_timer -= delta

	# Move toward player ONLY if farther than stop distance
	if distance_to_player > stop_distance:
		velocity = direction * normal_speed
	else:
		velocity = Vector2.ZERO

		# Shoot at player when in range
		if distance_to_player <= shoot_range and shoot_timer <= 0 and bullet_scene != null:
			_shoot_burst()
			shoot_timer = shoot_cooldown

	move_and_slide()


func _shoot_burst():
	for i in bullets_per_burst:
		await get_tree().create_timer(i * burst_delay).timeout
		_shoot_bullet()


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
		queue_free()
		if is_instance_valid(player) and player.has_method("add_points"):
			player.add_points(10)


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
