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
var boss_spawned := false

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
	round_number += 1
	to_spawn_this_round = start_round_size + (round_number - 1) * round_growth
	spawned_this_round = 0

	if is_instance_valid(player) and player.has_method("set_round"):
		player.set_round(round_number)

	# Spawn a boss every 3 rounds
	if round_number % 3 == 0 and not boss_scenes.is_empty():
		var boss_scene := boss_scenes[randi() % boss_scenes.size()]
		if %Bosses.get_child_count() == 0:
			var boss := boss_scene.instantiate()
			%Bosses.add_child(boss)
			(boss as Node2D).global_position = _pick_boss_spawn_position()
			boss.add_to_group("enemies")

			boss.tree_exited.connect(_on_spawned_enemy_exited_tree)

			print("BOSS ROUND! Round ", round_number)
	print("ROUND ", round_number, " | spawning ", to_spawn_this_round)
	_arm_next_spawn()


func _maybe_finish_round() -> void:
	# Called after spawns, and whenever an enemy dies
	if  spawned_this_round >= to_spawn_this_round and %Enemies.get_child_count() == 0 and %Bosses.get_child_count() == 0:
		print("ROUND ", round, " cleared!")
		_round_break_then_next()


func _round_break_then_next() -> void:
	# stop any pending spawn timer
	if _timer:
		_timer.stop()

	await get_tree().create_timer(break_between_rounds).timeout
	_start_next_round()


func _arm_next_spawn() -> void:

	# if we already spawned everything for this round, just wait for kills
	if spawned_this_round >= to_spawn_this_round and %Enemies.get_child_count() == 0 and %Bosses.get_child_count() == 0:
		_maybe_finish_round()
		return

	print("STARTING")
	_timer.wait_time = randf_range(min_wait, max_wait)
	_timer.start()

func _on_timeout() -> void:
	if enemy_scenes.is_empty():
		_arm_next_spawn()
		print('meow')
		return

	# round cap
	if spawned_this_round >= to_spawn_this_round:
		_arm_next_spawn()
		print('quack')
		return

	var scene := enemy_scenes[randi() % enemy_scenes.size()]
	if scene == null:
		_arm_next_spawn()
		print('arf')
		return

	var enemy := scene.instantiate()
	%Enemies.add_child(enemy)
	(enemy as Node2D).global_position = _pick_spawn_position()
	enemy.add_to_group("enemies")

	spawned_this_round += 1
	alive_from_this_spawner += 1

	# When the enemy is freed (dies), decrement alive count
	enemy.tree_exited.connect(_on_spawned_enemy_exited_tree)
	print('fuck you')
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
