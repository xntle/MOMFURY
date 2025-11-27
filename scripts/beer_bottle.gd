extends Area2D

@export var speed: float = 400.0
@export var max_distance: float = 200.0

var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2
var poison_floor_scene: PackedScene

func _ready() -> void:
	_start_position = global_position

func _physics_process(delta: float) -> void:
	# Move grenade
	global_position += direction * speed * delta

	# Rotate for style
	rotation += 10.0 * delta

	# Check distance traveled
	var traveled := _start_position.distance_to(global_position)
	if traveled >= max_distance:
		_spawn_poison_floor()
		queue_free()

func _stop_grenade() -> void:
	speed = 0
	direction = Vector2.ZERO
		
func _spawn_poison_floor() -> void:
	if poison_floor_scene == null:
		return

	_stop_grenade()
	var poison = poison_floor_scene.instantiate()

	get_tree().current_scene.add_child(poison)
	poison.global_position = global_position
	poison.time_alive = 0


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		call_deferred("_spawn_poison_floor")
		queue_free()
		body.take_damage(10)
