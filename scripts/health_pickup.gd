extends Area2D

@export var heal_amount: float = 20.0


func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController and body.current_health < body.max_health:
		body.current_health = min(body.current_health + heal_amount, body.max_health)
		body.emit_signal("health_changed", body.current_health)
		queue_free()
