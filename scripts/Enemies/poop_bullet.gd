extends Area2D

@export var speed: float = 200.0
@export var max_distance: float = 400.0
@export var damage: float = 8.0

var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2


func _ready():
	_start_position = global_position
	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	global_position += direction * speed * delta
	rotation += 5.0 * delta

	if _start_position.distance_to(global_position) >= max_distance:
		queue_free()


func _on_body_entered(body):
	# Only damage the player
	if body is PlayerController:
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.collision_layer & 2:  # Hit wall or obstacle
		queue_free()
