extends Area2D

@export var life_time: float = 3.0
@export var damage_per_second: float = 10.0
@export var tick_interval: float = 0.1
@export var slow_multiplier: float = 0.5  # Player moves at 50% speed in poison

var time_alive: float = 5.0
var damage_bodies: Array[Node] = []

@onready var damage_timer: Timer = $DamageTimer

func _ready() -> void:
	damage_timer.wait_time = tick_interval
	damage_timer.start()

func _physics_process(delta: float) -> void:
	time_alive += delta
	if time_alive >= life_time:
		_cleanup()
		queue_free()

func _cleanup() -> void:
	# Remove slow effect from all players still in the poison when it expires
	for body in damage_bodies:
		if is_instance_valid(body) and body is PlayerController:
			body.remove_slow()

func _on_body_entered(body) -> void:
	if body is PlayerController:
		if body not in damage_bodies:
			damage_bodies.append(body)
			body.apply_slow(slow_multiplier)


func _on_body_exited(body: Node2D) -> void:
	if body in damage_bodies:
		damage_bodies.erase(body)
		if body is PlayerController:
			body.remove_slow() 


func _on_damage_timer_timeout() -> void:
	for body in damage_bodies:
		if is_instance_valid(body):
			body.take_damage(damage_per_second*tick_interval)
