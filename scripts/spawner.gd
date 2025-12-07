extends StaticBody2D

@export var enemy_scenes: Array[PackedScene] = []  # <-- drag multiple enemies in here
@export var min_wait: float = 1.0
@export var max_wait: float = 3.0
@export var max_alive: int = 30
@export var spawn_radius: float = 0.0
@export var spawn_points: Array[NodePath] = []

# Health system
@export var max_health: float = 100.0
var current_health: float
var is_destroyed: bool = false

var _timer: Timer

func _ready() -> void:
	randomize()
	current_health = max_health

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	_arm_next_spawn()

func _arm_next_spawn() -> void:
	_timer.wait_time = randf_range(min_wait, max_wait)
	_timer.start()

func _on_timeout() -> void:
	# Don't spawn if destroyed
	if is_destroyed:
		return

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


# Health and damage system
func take_damage(amount: float) -> void:
	if is_destroyed:
		return

	current_health -= amount
	print("Spawner took ", amount, " damage. Health: ", current_health, "/", max_health)

	# Visual feedback - flash
	_flash_damage()

	if current_health <= 0:
		_destroy()


func _flash_damage() -> void:
	var sprite = get_node_or_null("Sprite2D")
	if sprite != null:
		sprite.modulate = Color(1.5, 0.5, 0.5)  # Red flash
		await get_tree().create_timer(0.1).timeout
		if sprite != null and not is_destroyed:
			sprite.modulate = Color(1, 1, 1)  # Back to normal


func _destroy() -> void:
	is_destroyed = true
	print("Spawner destroyed!")

	# Stop spawning
	if _timer != null:
		_timer.stop()

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Visual death effect
	var sprite = get_node_or_null("Sprite2D")
	if sprite != null:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
	else:
		# No sprite, just remove after delay
		await get_tree().create_timer(1.0).timeout
		queue_free()
