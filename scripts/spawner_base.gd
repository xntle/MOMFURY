class_name SpawnerBase
extends StaticBody2D

# Spawner properties
@export var max_health: float = 100.0
@export var spawn_interval: float = 3.0
@export var max_spawns: int = -1  # -1 = infinite
@export var spawn_radius: float = 50.0
@export var enemy_scenes: Array[PackedScene] = []

# Internal state
var current_health: float
var spawn_count: int = 0
var is_destroyed: bool = false
var spawn_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready():
	current_health = max_health
	spawn_timer = spawn_interval  # Spawn first enemy immediately after interval


func _process(delta):
	if is_destroyed:
		return

	# Update spawn timer
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_enemy()
		spawn_timer = spawn_interval


func _spawn_enemy() -> void:
	# Check if we've reached max spawns
	if max_spawns >= 0 and spawn_count >= max_spawns:
		return

	# Check if we have enemies to spawn
	if enemy_scenes.is_empty():
		print("ERROR: No enemy scenes configured for spawner!")
		return

	# Pick a random enemy type
	var enemy_scene = enemy_scenes.pick_random()
	var enemy = enemy_scene.instantiate()

	# Add to scene
	get_tree().current_scene.add_child(enemy)

	# Random position around spawner
	var random_angle = randf() * TAU
	var random_distance = randf() * spawn_radius
	var spawn_offset = Vector2(cos(random_angle), sin(random_angle)) * random_distance
	enemy.global_position = global_position + spawn_offset

	spawn_count += 1
	print("Spawner spawned enemy #", spawn_count)


func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	current_health -= amount
	print("Spawner took ", amount, " damage. Health: ", current_health, "/", max_health)

	# Visual feedback - flash red
	_flash_damage()

	if current_health <= 0:
		_destroy()


func _flash_damage() -> void:
	if sprite != null:
		sprite.modulate = Color(1.5, 0.5, 0.5)  # Red tint
		await get_tree().create_timer(0.1).timeout
		if sprite != null and not is_destroyed:
			sprite.modulate = Color(1, 1, 1)  # Back to normal


func _destroy() -> void:
	is_destroyed = true
	print("Spawner destroyed!")

	# Visual death effect
	if sprite != null:
		sprite.modulate = Color(0.3, 0.3, 0.3)  # Darken

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Fade out and destroy
	var tween = create_tween()
	if sprite != null:
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)
