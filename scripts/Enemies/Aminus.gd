extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")

var normal_speed := 40.0
var stop_distance := 70.0

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	var distance_to_player = global_position.distance_to(player.global_position)

	# Move toward player ONLY if farther than stop distance
	if distance_to_player > stop_distance:
		velocity = direction * normal_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
