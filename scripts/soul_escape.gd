extends Node2D

@export var rise_speed: float = 100.0
@export var rise_duration: float = 1.5
@export var fade_duration: float = 1.0
@export var explosion_force: float = 150.0

@onready var particles: CPUParticles2D = $Particles

func _ready() -> void:
	# Create visual soul circle
	_create_soul_visual()

	# Start explosive animation
	_animate_explosion()

func _create_soul_visual() -> void:


	# Use particles to create the soul glow effect
	if particles:
		particles.emitting = true

func _animate_explosion() -> void:
	# Explosive rise with random direction
	var random_offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))

	var tween = create_tween()
	tween.set_parallel(true)

	# Explosive rise up
	tween.tween_property(self, "position", position + Vector2(random_offset.x, -rise_speed * rise_duration + random_offset.y), rise_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

	# Spin randomly
	tween.tween_property(self, "rotation", randf_range(-PI * 2, PI * 2), rise_duration).set_ease(Tween.EASE_OUT)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, fade_duration).set_ease(Tween.EASE_IN).set_delay(rise_duration - fade_duration)

	# Clean up
	await tween.finished
	queue_free()
