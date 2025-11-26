extends CharacterBody2D
class_name PlayerController

@export var move_speed = 20.0
@export var roll_speed = 300.0
@export var roll_time = 0.15
@export var roll_cooldown = 0.4

var direction: Vector2
var is_rolling = false
var roll_timer = 0.0
var cooldown_timer = 0.0
var roll_dir: Vector2

var normal_mask = 0
@export var roll_mask = 0

func _ready():
	normal_mask = collision_mask


func _physics_process(delta):
	# cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# --- ROLLING ---
	if is_rolling:
		roll_timer -= delta
		velocity = roll_dir * roll_speed
		move_and_slide()

		# ROLL END
		if roll_timer <= 0:
			is_rolling = false
			cooldown_timer = roll_cooldown

			# RESTORE NORMAL COLLISION
			collision_mask = normal_mask

		return

	# --- movement input ---
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

	# --- ROLL TRIGGER ---
	if Input.is_action_just_pressed("roll") and cooldown_timer <= 0 and direction != Vector2.ZERO:
		is_rolling = true
		roll_timer = roll_time
		roll_dir = direction.normalized()

		# ENABLE ROLL COLLISION MASK
		collision_mask = roll_mask

		return

	# normal movement
	velocity = move_speed * direction * delta * 200
	move_and_slide()
