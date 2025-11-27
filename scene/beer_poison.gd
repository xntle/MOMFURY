extends StaticBody2D

@export var life_time: float = 3.0
@export var damage_per_second: float = 10.0

var time_alive: float = 5.0

func _physics_process(delta: float) -> void:
	#print(_time_alive)
	time_alive += delta
	if time_alive >= life_time:
		queue_free()

func _on_body_entered(body) -> void:
	print("HI", body)
