extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 30.0
@export var roll_speed: float = 300.0
@export var roll_time: float = 0.15
@export var roll_cooldown: float = 0.4
@export var max_health: float = 100.0

var current_health = max_health
var direction: Vector2
var is_rolling:bool = false
var roll_timer:float = 0.0
var cooldown_timer:float = 0.0
var roll_dir: Vector2

signal health_changed(new_health:int)

@export var roll_mask = 4
var normal_mask = 6


func _ready():
	normal_mask = collision_mask


func _physics_process(delta):
	# cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# dodge rolling condition
	if is_rolling:
		roll_timer -= delta

		move_and_collide(roll_dir * roll_speed * delta)

		if roll_timer <= 0:
			is_rolling = false
			cooldown_timer = roll_cooldown
			collision_mask = normal_mask
			return

		return  

	# movement input
	if Input.is_action_pressed("move_down"):
		direction.y = 1
	elif Input.is_action_pressed("move_up"):
		direction.y = -1
	else:
		direction.y = 0

	if Input.is_action_pressed("move_right"):
		direction.x = 1
	elif Input.is_action_pressed("move_left"):
		direction.x = -1
	else:
		direction.x = 0

	if current_health >= max_health:
		current_health = max_health
	if current_health <= 0.0:
		current_health = 0.0
		#Add death logic here 
		get_tree().change_scene_to_file("res://scene/main_menu.tscn") 


	# dodge rolling
	if Input.is_action_just_pressed("roll") and cooldown_timer <= 0 and direction != Vector2.ZERO:
		is_rolling = true
		roll_timer = roll_time
		roll_dir = direction.normalized()
		collision_mask = roll_mask
		

		return




	# normal movement
	velocity = move_speed * direction * delta * 200

	move_and_slide()
	
func _on_body_entered(body) -> void:
	print("ENTERE", body)
#Damage function
func take_damage(amount: int) -> void:
	current_health -= amount
	emit_signal("health_changed", current_health)
