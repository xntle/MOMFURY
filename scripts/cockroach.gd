extends CharacterBody2D

@onready var player: CharacterBody2D = get_node("/root/Game/Player")

@export var health: float = 100.0
@export var speed: float = 50.0
@export var damage: float = 10.0

var dash_timer: float = 0.0
var dash_speed: float = 250.0
var is_dashing: bool = false
var dash_duration: float = 0.2
var dash_time_left: float = 0.0
var bounce_timer: float = 0.0
var default_bounce_timer: float = 0.25


func _ready():
	# First random cooldown 1 to 3 seconds
	dash_timer = randf_range(1.0, 3.0)  

func _physics_process(delta):
	
	bounce_timer = max(0.0,bounce_timer-delta)
	dash_timer = max(0.0,dash_timer-delta)

	var direction = global_position.direction_to(player.global_position)

	
	# Start a dash when timer hits zero
	if dash_timer <= 0.0:
		is_dashing = true
		dash_time_left = dash_duration
		dash_timer = randf_range(1.0, 3.0)

	# Dash or normal move or bounce
	if is_dashing:
		velocity = direction * dash_speed
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false

#Only bounces until the last 0.1s, then stands still to simulate recoil.
	elif bounce_timer >= 0.1:
		velocity = -4 * direction * speed
	elif bounce_timer == 0:
		velocity = direction * speed
	else:
		velocity = Vector2(0,0)

#For 0.5 seconds before the dash, the cockroach stands still as a warning.

	if (not (dash_timer>0 and dash_timer<=0.5)):
		move_and_slide()
	rotation = direction.angle() +90


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(damage)
		bounce_timer+=default_bounce_timer
		is_dashing = false
		dash_timer = randf_range(1.0, 3.0)  
