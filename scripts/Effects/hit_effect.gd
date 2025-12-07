extends CPUParticles2D

func _ready():
	emitting = true
	# Auto-delete after particles finish
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
