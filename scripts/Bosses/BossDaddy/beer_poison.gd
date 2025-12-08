extends Area2D

@export var life_time: float = 3.0
@export var tick_interval: float = 0.1

@export_group("Damage Settings")
@export var base_dps: float = 10.0      # starting damage per second
@export var ramp_dps_per_sec: float = 15.0  # how much DPS increases per second stayed in beam
@export var max_dps: float = 120.0      # cap (optional)

@export_group("Movement Settings")
@export var turn_speed: float = 1.0 
@export_range(0.1, 1.0) var slow_multiplier: float = 0.5 # 0.5 = Half speed

@onready var player = get_node("/root/Game/Player")
@onready var damage_timer: Timer = $DamageTimer

var time_alive := 0.0

# Store time-in-beam per body
var bodies_in_beam: Dictionary = {} # body -> time_inside_seconds

func _ready() -> void:
	damage_timer.wait_time = tick_interval
	damage_timer.start()

func _physics_process(delta: float) -> void:
	time_alive += delta
	
	if is_instance_valid(player):
		var target_angle = (player.global_position - global_position).angle()
		rotation = lerp_angle(rotation, target_angle, turn_speed * delta)
			
	if time_alive >= life_time:
		_reset_all_slows()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		# start tracking time inside
		bodies_in_beam[body] = 0.0
		
		# UPDATED: Call the function you created in PlayerController
		if body.has_method("apply_slow"):
			body.apply_slow(slow_multiplier)

func _on_body_exited(body: Node2D) -> void:
	if bodies_in_beam.has(body):
		bodies_in_beam.erase(body)
		
		# UPDATED: Remove slow using the function
		if is_instance_valid(body) and body.has_method("remove_slow"):
			body.remove_slow()

func _reset_all_slows() -> void:
	for body in bodies_in_beam.keys():
		if is_instance_valid(body) and body.has_method("remove_slow"):
			body.remove_slow()
	bodies_in_beam.clear()

func _on_damage_timer_timeout() -> void:
	for body in bodies_in_beam.keys():
		if not is_instance_valid(body):
			bodies_in_beam.erase(body)
			continue
		if not (body is PlayerController):
			continue

		# ramp time
		bodies_in_beam[body] += tick_interval
		var t: float = bodies_in_beam[body]

		# ramping DPS
		var dps := base_dps + ramp_dps_per_sec * t
		dps = min(dps, max_dps)

		var damage := dps * tick_interval
		
		# Ensure we call take_damage on the player
		if body.has_method("take_damage"):
			body.take_damage(damage)
