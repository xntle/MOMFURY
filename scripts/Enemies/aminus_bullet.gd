extends Area2D

@export var speed: float = 250.0
@export var max_distance: float = 500.0
@export var damage: float = 12.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.ZERO
var travel_time:float = 0.0


func _ready():
	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	global_position += direction * speed * delta
	rotation = direction.angle()

	travel_time += delta
	if travel_time >= lifetime:
		queue_free()


func _on_body_entered(body):
	# Only damage the player
	if body is PlayerController:
		if body.has_method("take_damage"):
			body.take_damage(damage)
	queue_free()
