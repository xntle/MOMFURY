extends Node2D

@export var boss_scene: PackedScene
@export var boss_spawn_position: Vector2 = Vector2(300, 150)

var spawners: Array[Node] = []
var boss_spawned: bool = false

func _ready() -> void:
	# Find all spawners in the scene
	call_deferred("_initialize_spawners")

func _initialize_spawners() -> void:
	# Get all nodes that are spawners
	spawners = get_tree().get_nodes_in_group("spawners")

	if spawners.is_empty():
		print("Warning: No spawners found in 'spawners' group!")
	else:
		print("Game Manager: Found ", spawners.size(), " spawners")

func _process(_delta: float) -> void:
	if boss_spawned:
		return

	# Check if all spawners are destroyed
	_check_spawners()

func _check_spawners() -> void:
	# Filter out any spawners that have been freed
	spawners = spawners.filter(func(spawner): return is_instance_valid(spawner))

	# If all spawners are destroyed, spawn the boss
	if spawners.is_empty():
		_spawn_boss()

func _spawn_boss() -> void:
	if boss_spawned:
		return

	boss_spawned = true
	print("All spawners destroyed! Spawning boss...")

	if boss_scene == null:
		print("ERROR: Boss scene not set in Game Manager!")
		return

	var boss = boss_scene.instantiate()
	add_child(boss)
	boss.global_position = boss_spawn_position
	boss.add_to_group("enemies")

	print("Boss spawned at position: ", boss_spawn_position)
