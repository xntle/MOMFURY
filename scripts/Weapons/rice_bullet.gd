extends Area2D

@export var speed: float = 500.0
@export var max_distance: float = 400.0
@export var damage: float = 10.0
@export var hit_effect_scene: PackedScene

var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2


func _ready():
	_start_position = global_position
	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	# Move bullet fast in preset direction
	global_position += direction * speed * delta

	# Slight rotation
	rotation += 8.0 * delta

	# Destroy if traveled too far
	if _start_position.distance_to(global_position) >= max_distance:
		queue_free()


func _on_body_entered(body):
	# Don't hit the player who shot it
	if body is PlayerController:
		return

	# Damage enemies
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Rice bullet hit: ", body.name, " for ", damage, " damage")

		# Spawn hit effect
		if hit_effect_scene != null:
			var hit_effect = hit_effect_scene.instantiate()
			get_tree().current_scene.add_child(hit_effect)
			hit_effect.global_position = global_position

	# Destroy bullet on impact
	queue_free()
