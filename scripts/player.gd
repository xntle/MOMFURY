extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 30.0
@export var roll_speed: float = 300.0
@export var roll_time: float = 0.15
@export var roll_cooldown: float = 0.4
@export var max_health: float = 100.0

# Weapon system
@export var slipper_scene: PackedScene
@export var rice_bullet_scene: PackedScene
@export var shoot_cooldown: float = 0.3

enum Weapon { SLIPPER, RICE_MACHINE }
var current_weapon: Weapon = Weapon.SLIPPER

var current_health: float = max_health
var direction: Vector2
var is_rolling:bool = false
var roll_timer:float = 0.0
var cooldown_timer:float = 0.0
var roll_dir: Vector2
var is_stunned:bool = false
var stun_timer:float = 0.0
var intangibility_timer:float = 0.0
var shoot_timer: float = 0.0

signal health_changed(new_health:int)



var last_move_dir: Vector2 = Vector2.DOWN
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var shoot_point: Marker2D = $ShootingPoint
@onready var slip_weapon: Node2D = $slip
@onready var rice_weapon: Node2D = $Ricechine

# Slow effect tracking
var is_slowed: bool = false
var slow_multiplier: float = 1.0

func _ready():
	#$AnimationPlayer.play("idle_down")
	anim.play("idle_down")

	# Initialize weapon visibility
	_update_weapon_visibility()


func _physics_process(delta):
	# cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# shoot cooldown
	if shoot_timer > 0:
		shoot_timer -= delta

	# dodge rolling condition
	if is_rolling:
		roll_timer -= delta

		move_and_collide(roll_dir * roll_speed * delta)

		if roll_timer <= 0:
			is_rolling = false
			cooldown_timer = roll_cooldown
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

	# weapon switching 
	if Input.is_action_just_pressed("switch"):
		_switch_weapon()

	# shooting with current weapon
	if Input.is_action_pressed("shoot") and shoot_timer <= 0.0 and not is_rolling and not is_stunned:
		_shoot_current_weapon()
		shoot_timer = shoot_cooldown

	# dodge rolling
	if Input.is_action_just_pressed("roll") and cooldown_timer <= 0.0 and (not is_stunned):
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
		collision_layer = 8
		anim.play("roll")
		return

	# normal movement
	velocity = move_speed * slow_multiplier * direction * delta * 200

	if not is_stunned:
		move_and_slide()
		
	# stun duration logic
	stun_timer = max(0,stun_timer-delta)
	if stun_timer <= 0:
		is_stunned = false
	
	# intangibility duration logic
	intangibility_timer = max(0,intangibility_timer-delta)
	if intangibility_timer <= 0:
		if not is_rolling:
			collision_layer = 1
	_update_animation()

## Animation
func _get_anim_name(dir: Vector2, is_moving: bool) -> String:
	if is_stunned:
		return "roll"
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

# Slow effect functions
func apply_slow(multiplier: float) -> void:
	is_slowed = true
	slow_multiplier = multiplier

func remove_slow() -> void:
	is_slowed = false
	slow_multiplier = 1.0
	
func apply_stun(duration) -> void:
	stun_timer = duration
	is_stunned = true

func apply_intangibility(duration) -> void:
	intangibility_timer = duration
	collision_layer = 8

func _shoot_slipper() -> void:
	if slipper_scene == null:
		print("ERROR: slipper_scene is null! Assign the Slipper scene in the Godot editor.")
		return

	var slipper = slipper_scene.instantiate()
	get_tree().current_scene.add_child(slipper)

	if shoot_point != null:
		slipper.global_position = shoot_point.global_position
	else:
		slipper.global_position = global_position

	var mouse_pos = get_global_mouse_position()
	slipper.direction = (mouse_pos - global_position).normalized()

# Shoot rice machine gun bullet
func _shoot_rice() -> void:
	if rice_bullet_scene == null:
		print("ERROR: rice_bullet_scene is null!")
		return

	var bullet = rice_bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	if shoot_point != null:
		bullet.global_position = shoot_point.global_position
	else:
		bullet.global_position = global_position

	var mouse_pos = get_global_mouse_position()
	bullet.direction = (mouse_pos - global_position).normalized()

# Shoot with current weapon
func _shoot_current_weapon() -> void:
	match current_weapon:
		Weapon.SLIPPER:
			_shoot_slipper()
		Weapon.RICE_MACHINE:
			_shoot_rice()

# Switch between weapons
func _switch_weapon() -> void:
	if current_weapon == Weapon.SLIPPER:
		current_weapon = Weapon.RICE_MACHINE
		print("Switched to Rice Machine Gun")
	else:
		current_weapon = Weapon.SLIPPER
		print("Switched to Slipper")

	_update_weapon_visibility()

# Update weapon visibility based on current weapon
func _update_weapon_visibility() -> void:
	if slip_weapon != null:
		slip_weapon.visible = (current_weapon == Weapon.SLIPPER)

	if rice_weapon != null:
		rice_weapon.visible = (current_weapon == Weapon.RICE_MACHINE)
