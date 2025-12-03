extends Area2D

@export var speed: float = 175.0
@export var max_distance: float = 20000.0
@export var poison_floor_scene: PackedScene

var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2


func _ready() -> void:
	_start_position = global_position

func _physics_process(delta: float) -> void:
	# Move grenade
	position += direction * speed * delta

	# Check distance traveled
	var traveled := _start_position.distance_to(global_position)
	if traveled >= max_distance:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	call_deferred("queue_free")
	if body is PlayerController:
		body.take_damage(5)
