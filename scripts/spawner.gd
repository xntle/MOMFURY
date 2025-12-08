extends StaticBody2D

@onready var player := get_node("/root/Game/Player")

@export var boss_scenes: Array[PackedScene] = [] 
@export var boss_spawn_points: Array[NodePath] = [] 
@export var enemy_scenes: Array[PackedScene] = []
@export var min_wait: float = 0.3
@export var max_wait: float = 1.2
@export var max_alive: int = 30
@export var spawn_radius: float = 0.0
@export var spawn_points: Array[NodePath] = []

# ROUNDS
@export var start_round_size: int = 5
@export var round_growth: int = 5
@export var break_between_rounds: float = 2.0
var round_number: int = 0
var to_spawn_this_round: int = 0
var spawned_this_round: int = 0
var alive_from_this_spawner: int = 0

# Health system
@export var max_health: float = 100.0
var current_health: float
var is_destroyed: bool = false

var _timer: Timer

func _ready() -> void:
	randomize()
	current_health = max_health
	add_to_group("spawners")

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)

	_start_next_round()
	
func _pick_boss_spawn_position() -> Vector2:
	if boss_spawn_points.size() > 0:
		var p := get_node_or_null(boss_spawn_points[randi() % boss_spawn_points.size()]) as Node2D
		if p:
			return p.global_position
	return _pick_spawn_position()


func _start_next_round() -> void:
	if is_destroyed:
		return

	round_number += 1
	to_spawn_this_round = start_round_size + (round_number - 1) * round_growth
	spawned_this_round = 0

	if is_instance_valid(player) and player.has_method("set_round"):
		player.set_round(round_number)

	# Spawn a boss every 5 rounds
	if round_number % 3 == 0 and not boss_scenes.is_empty():
		var boss_scene := boss_scenes[randi() % boss_scenes.size()]
		if boss_scene != null:
			var boss := boss_scene.instantiate()
			%Enemies.add_child(boss)
			(boss as Node2D).global_position = _pick_boss_spawn_position()
			boss.add_to_group("enemies")

			alive_from_this_spawner += 1
			boss.tree_exited.connect(_on_spawned_enemy_exited_tree)

			print("BOSS ROUND! Round ", round_number)
	print("ROUND ", round_number, " | spawning ", to_spawn_this_round)
	_arm_next_spawn()


func _maybe_finish_round() -> void:
	# Called after spawns, and whenever an enemy dies
	if spawned_this_round >= to_spawn_this_round and alive_from_this_spawner <= 0 and not is_destroyed:
		print("ROUND ", round, " cleared!")
		_round_break_then_next()


func _round_break_then_next() -> void:
	# stop any pending spawn timer
	if _timer:
		_timer.stop()

	# Check if tree is valid before creating timer
	if not is_instance_valid(self) or get_tree() == null:
		return

	await get_tree().create_timer(break_between_rounds).timeout

	# Check again after await in case scene changed
	if not is_instance_valid(self) or get_tree() == null:
		return

	_start_next_round()


func _arm_next_spawn() -> void:
	if is_destroyed:
		return

	# if we already spawned everything for this round, just wait for kills
	if spawned_this_round >= to_spawn_this_round:
		_maybe_finish_round()
		return

	_timer.wait_time = randf_range(min_wait, max_wait)
	_timer.start()

func _on_timeout() -> void:
	if is_destroyed:
		return

	if enemy_scenes.is_empty():
		_arm_next_spawn()
		return

	# global cap (optional): total enemies under %Enemies
	if max_alive > 0 and %Enemies.get_child_count() >= max_alive:
		_arm_next_spawn()
		return

	# round cap
	if spawned_this_round >= to_spawn_this_round:
		_arm_next_spawn()
		return

	var scene := enemy_scenes[randi() % enemy_scenes.size()]
	if scene == null:
		_arm_next_spawn()
		return

	var enemy := scene.instantiate()
	%Enemies.add_child(enemy)
	(enemy as Node2D).global_position = _pick_spawn_position()
	enemy.add_to_group("enemies")

	spawned_this_round += 1
	alive_from_this_spawner += 1

	# When the enemy is freed (dies), decrement alive count
	enemy.tree_exited.connect(_on_spawned_enemy_exited_tree)

	_arm_next_spawn()

func _on_spawned_enemy_exited_tree() -> void:
	alive_from_this_spawner = max(0, alive_from_this_spawner - 1)
	_maybe_finish_round()

func _pick_spawn_position() -> Vector2:
	if spawn_points.size() > 0:
		var path: NodePath = spawn_points[randi() % spawn_points.size()]
		var p := get_node_or_null(path) as Node2D
		if p:
			return p.global_position

	if spawn_radius > 0.0:
		return global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(0.0, spawn_radius)

	return global_position

# ---------------- HEALTH / DESTROY ----------------

func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	current_health -= amount
	print("Spawner took ", amount, " damage. Health: ", current_health, "/", max_health)
	_flash_damage()

	if current_health <= 0:
		_destroy()

func _flash_damage() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite != null:
		sprite.modulate = Color(1.5, 0.5, 0.5)

		# Check if tree is valid
		if get_tree() == null:
			return

		await get_tree().create_timer(0.1).timeout

		if sprite != null and not is_destroyed:
			sprite.modulate = Color(1, 1, 1)

func _destroy() -> void:
	is_destroyed = true
	print("Spawner destroyed!")

	if _timer != null:
		_timer.stop()

	collision_layer = 0
	collision_mask = 0

	var sprite = get_node_or_null("Sprite2D")
	if sprite != null:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
	else:
		# Check if tree is valid
		if get_tree() != null:
			await get_tree().create_timer(1.0).timeout
		queue_free()
