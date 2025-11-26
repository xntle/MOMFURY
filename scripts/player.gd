extends CharacterBody2D
class_name PlayerController

@export var move_speed = 20.0

var direction : Vector2

func _physics_process(delta):
	# Y value of player input
	if Input.is_action_pressed("move_down"):
		direction.y = 1
	elif Input.is_action_pressed("move_up"):
		direction.y = -1
	else: 
		direction.y = 0
	
	# X value of player input
	if Input.is_action_pressed("move_right"):
		direction.x = 1
	elif Input.is_action_pressed("move_left"):
		direction.x = -1
	else:
		direction.x = 0
		
	velocity = move_speed * direction * delta * 200
	move_and_slide()
	
		
		
