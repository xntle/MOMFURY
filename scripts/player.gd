extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 30.0
@export var roll_speed: float = 300.0
@export var roll_time: float = 0.15
@export var roll_cooldown: float = 0.4
@export var max_health: float = 100.0

var current_health: float = max_health
var direction: Vector2
var is_rolling:bool = false
var roll_timer:float = 0.0
var cooldown_timer:float = 0.0
var roll_dir: Vector2

signal health_changed(new_health:int)



var last_move_dir: Vector2 = Vector2.DOWN
@onready var anim: AnimationPlayer = $AnimationPlayer

func _ready():
	#$AnimationPlayer.play("idle_down")
	anim.play("idle_down")


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
			set_collision_mask_value(2, true)
			collision_layer = 1
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
		
	# normalize diagonal speed
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		last_move_dir = direction

	if current_health >= max_health:
		current_health = max_health
	if current_health <= 0.0:
		current_health = 0.0
		#Add death logic here 
		get_tree().change_scene_to_file("res://scene/main_menu.tscn") 


	# dodge rolling
	if Input.is_action_just_pressed("roll") and cooldown_timer <= 0.0:
		var roll_input_dir := direction

		# If no current input, roll in the last move direction (facing)
		if roll_input_dir == Vector2.ZERO:
			roll_input_dir = last_move_dir

	# Safety: if last_move_dir was ever zero (just in case), don't start roll
		if roll_input_dir == Vector2.ZERO:
			return

		is_rolling = true
		roll_timer = roll_time
		roll_dir = roll_input_dir.normalized()
		set_collision_mask_value(2, false)
		collision_layer = 8
		anim.play("roll")
		return

	# normal movement
	velocity = move_speed * direction * delta * 200

	move_and_slide()
	
	_update_animation()

## Animation
func _get_anim_name(dir: Vector2, is_moving: bool) -> String:
	if not is_moving:
		return "idle_down"  # your only idle anim for now

	var x := dir.x
	var y := dir.y

	# PURE CARDINAL DIRECTIONS
	if abs(x) < 0.4 and y < -0.4:
		return "move_up"
	elif x < -0.4 and abs(y) < 0.4:
		return "move_left"
	elif x > 0.4 and abs(y) < 0.4:
		return "move_right"

	## DIAGONALS (any time both x and y have a decent magnitude)
	#if x < 0.0:
		#return "move_diag_left_up"
	#elif x > 0.0:
		#return "move_diag_right_up"
	if abs(x) > 0.4 and abs(y) > 0.4:
		# UP
		if y < 0.0:
			return "move_diag_left_up" if x < 0.0 else "move_diag_right_up"
		# DOWN
		else:
			return "move_diag_left_down" if x < 0.0 else "idle_down"

	 

	# moving straight down but you don't have move_down yet → reuse idle_down
	return "idle_down"


func _update_animation() -> void:
	if is_rolling:
		if anim.current_animation != "roll":
			anim.play("roll")
		return
		
	var is_moving := direction != Vector2.ZERO and not is_rolling
	var dir_vec := last_move_dir

	var anim_name := _get_anim_name(dir_vec, is_moving)

	if anim.current_animation != anim_name:
		anim.play(anim_name)
		
		
func _on_body_entered(body) -> void:
	print("ENTERE", body)
#Damage function
func take_damage(amount: int) -> void:
	current_health -= amount
	emit_signal("health_changed", current_health)
