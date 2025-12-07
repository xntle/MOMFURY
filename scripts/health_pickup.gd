extends Area2D

@export var heal_amount: float = 20.0


func _ready():
	body_entered.connect(_on_body_entered)

	# Add a small floating animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "position:y", position.y - 5, 0.8).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", position.y + 5, 0.8).set_trans(Tween.TRANS_SINE)


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
