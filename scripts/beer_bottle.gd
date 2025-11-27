extends Area2D

@export var speed: float = 150.0
var direction: Vector2 = Vector2.RIGHT
@export var life_time: float = 2.0

var _time_alive: float = 0.0

func _physics_process(delta: float) -> void:
	# Move the projectile
	position += direction * speed * delta

	# Track lifetime and free when done
	_time_alive += delta
	if _time_alive >= life_time:
		queue_free()

func _on_body_entered(body: Node) -> void:
	# Example: if the body has a health script or is an enemy
	if body.has_method("take_damage"):
		body.take_damage(1)
	queue_free()  # destroy projectile on hit
