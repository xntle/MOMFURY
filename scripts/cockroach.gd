extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var dash_timer := 0.0
var dash_speed := 250.0
var normal_speed := 40.0
var is_dashing := false
var dash_duration := 0.2
var dash_time_left := 0.0

func _ready():
	# First random cooldown 1 to 3 seconds
	dash_timer = randf_range(1.0, 3.0)  

func _physics_process(delta):
	dash_timer -= delta

	var direction = global_position.direction_to(player.global_position)

	# Start a dash when timer hits zero
	if dash_timer <= 0.0:
		is_dashing = true
		dash_time_left = dash_duration
		dash_timer = randf_range(1.0, 3.0)

	# Dash or normal move
	if is_dashing:
		velocity = direction * dash_speed
		dash_time_left -= delta
		if dash_time_left <= 0:
			is_dashing = false
	else:
		velocity = direction * normal_speed

	move_and_slide()
	rotation = direction.angle() +90
