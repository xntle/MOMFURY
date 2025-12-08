extends Area2D

@export var heal_amount: float = 20.0

var initial_position: Vector2
var float_time: float = 0.0
var float_amplitude: float = 5.0
var float_speed: float = 2.0
var position_initialized: bool = false


func _ready():
	body_entered.connect(_on_body_entered)


func _process(delta):
	# Store initial position on first frame (after enemy sets the position)
	if not position_initialized:
		initial_position = global_position
		position_initialized = true

	# Create smooth floating animation using sine wave
	float_time += delta * float_speed
	var offset = sin(float_time) * float_amplitude
	global_position = initial_position + Vector2(0, offset)


func _on_body_entered(body):
	if body is PlayerController:
		# Heal the player
		if body.current_health < body.max_health:
			body.current_health = min(body.current_health + heal_amount, body.max_health)
			body.emit_signal("health_changed", body.current_health)
			print("Player healed! Health: ", body.current_health, "/", body.max_health)

			# Play pickup effect (optional sound/particle here)
			queue_free()
		else:
			# Already at max health
			print("Player at max health, can't pick up")
