extends CPUParticles2D

func _ready():
	# Start emitting
	emitting = true

	# Auto-delete after particles finish
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()
