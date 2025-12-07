extends Node2D

@export var enemy_scenes: Array[PackedScene] = []  # <-- drag multiple enemies in here
@export var min_wait: float = 1.0
@export var max_wait: float = 3.0
@export var max_alive: int = 30
@export var spawn_radius: float = 0.0
@export var spawn_points: Array[NodePath] = []

var _timer: Timer

func _ready() -> void:
	randomize()
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	_arm_next_spawn()

func _arm_next_spawn() -> void:
	_timer.wait_time = randf_range(min_wait, max_wait)
	_timer.start()

func _on_timeout() -> void:
	if enemy_scenes.is_empty():
		_arm_next_spawn()
		return

	if max_alive > 0 and %Enemies.get_child_count() >= max_alive:
		_arm_next_spawn()
		return

	# pick a random enemy scene
	var scene := enemy_scenes[randi() % enemy_scenes.size()]
	if scene == null:
		_arm_next_spawn()
		return

	var enemy := scene.instantiate()
	%Enemies.add_child(enemy)

	(enemy as Node2D).global_position = _pick_spawn_position()
	enemy.add_to_group("enemies")

	_arm_next_spawn()

func _pick_spawn_position() -> Vector2:
	if spawn_points.size() > 0:
		var path: NodePath = spawn_points[randi() % spawn_points.size()]
		var p := get_node_or_null(path) as Node2D
		if p:
			return p.global_position

	if spawn_radius > 0.0:
		return global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, spawn_radius)

	return global_position
