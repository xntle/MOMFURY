extends Area2D

@export var speed: float = 400.0
@export var max_distance: float = 500.0
@export var damage: float = 20.0
@export var hit_effect_scene: PackedScene

var direction: Vector2 = Vector2.ZERO
var _start_position: Vector2

func _ready():
	_start_position = global_position
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += direction * speed * delta
	rotation += 15.0 * delta

	if _start_position.distance_to(global_position) >= max_distance:
		queue_free()

func _on_body_entered(body):
	print("Slipper bullet hit: ", body.name, " (", body.get_class(), ")")

	if body is PlayerController:
		print("  -> Ignoring player")
		return

	if body.has_method("take_damage"):
		print("  -> Dealing ", damage, " damage")
		body.take_damage(damage)

		# Spawn hit effect
		if hit_effect_scene != null:
			var hit_effect = hit_effect_scene.instantiate()
			get_tree().current_scene.add_child(hit_effect)
			hit_effect.global_position = global_position
	else:
		print("  -> No take_damage method found")

	queue_free()
