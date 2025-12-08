extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 30.0
@export var roll_speed: float = 300.0
@export var roll_time: float = 0.15
@export var roll_cooldown: float = 0.4
@export var max_health: float = 100.0

# Weapon system
enum Weapon { SLIPPER, RICE_MACHINE, BROOM }
var current_weapon: Weapon = Weapon.SLIPPER

var current_health: float = max_health
var current_points: float = 0.0
var direction: Vector2
var is_rolling: bool = false
var roll_timer: float = 0.0
var cooldown_timer: float = 0.0
var roll_dir: Vector2
var is_stunned: bool = false
var stun_timer: float = 0.0
var intangibility_timer: float = 0.0

# Hit state
var is_hit: bool = false
var hit_timer: float = 0.0
var hit_duration: float = 0.25
var is_dead: bool = false    # <-- NEW (Manages the death state)


signal health_changed(new_health:int)
signal points_changed(new_points: int)
signal round_changed(new_round: int)

var last_move_dir: Vector2 = Vector2.DOWN  

@onready var anim: AnimatedSprite2D = $animation
var current_round: int = 1

@onready var shoot_point: Marker2D = $ShootingPoint
@onready var slip_weapon: Node2D = $slip
@onready var rice_weapon: Node2D = $Ricechine
@onready var broom_weapon: Node2D = $Broom
@onready var movement_trail: CPUParticles2D = $MovementTrail

# Slow effect tracking
var is_slowed: bool = false
var slow_multiplier: float = 1.0

func _ready():
	if anim:
		anim.play("idle_down")
	_update_weapon_visibility()
	anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta):
	# cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	# update hit timer
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			is_hit = false

	# === DEATH STATE MANAGEMENT ===
	if is_dead:
		# Lock movement, reset roll, stop effects, and return to skip input processing
		velocity = Vector2.ZERO
		is_rolling = false
		if movement_trail:
			movement_trail.emitting = false
		move_and_slide()
		_update_animation()
		return
	# ==============================

	# dodge rolling condition
	if is_rolling:
		roll_timer -= delta
		move_and_collide(roll_dir * roll_speed * delta)

		# Emit intense trail during roll
		if movement_trail != null:
			movement_trail.emitting = true
			movement_trail.amount = 15
			movement_trail.scale_amount_max = 6.0

		if roll_timer <= 0.0:
			is_rolling = false
			cooldown_timer = roll_cooldown
			collision_layer = 1
		return  # Skip all movement/input when rolling

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
		_update_weapon_layering()

	# health clamp
	if current_health >= max_health:
		current_health = max_health
	if current_health <= 0.0:
		current_health = 0.0
		# REMOVED: Immediate scene change here. Death is handled by take_damage.

	# weapon switching
	if Input.is_action_just_pressed("switch"):
		_switch_weapon()

	# shooting with current weapon
	if Input.is_action_pressed("shoot") and not is_rolling and not is_stunned:
		_shoot_current_weapon()

	# dodge rolling
	if Input.is_action_just_pressed("roll") and cooldown_timer <= 0.0 and (not is_stunned):
		var roll_input_dir := direction

		# If no current input, roll in the last move direction (facing)
		if roll_input_dir == Vector2.ZERO:
			roll_input_dir = last_move_dir

		if roll_input_dir == Vector2.ZERO:
			return

		is_rolling = true
		roll_timer = roll_time
		roll_dir = roll_input_dir.normalized()
		collision_layer = 8
		if anim:
			anim.play("roll")
		return

	# normal movement
	velocity = move_speed * slow_multiplier * direction * delta * 200.0

	if not is_stunned:
		move_and_slide()

	# Update movement trail
	if movement_trail != null:
		if direction != Vector2.ZERO and not is_stunned:
			movement_trail.emitting = true
			movement_trail.amount = 8
			movement_trail.scale_amount_max = 4.0
		else:
			movement_trail.emitting = false

	# stun duration logic
	stun_timer = max(0.0, stun_timer - delta)
	if stun_timer <= 0.0:
		is_stunned = false
	
	# intangibility duration logic
	intangibility_timer = max(0.0, intangibility_timer - delta)
	if intangibility_timer <= 0.0:
		if not is_rolling:
			collision_layer = 1

	_update_animation()

## Animation name helpers
func _get_anim_name(dir: Vector2, is_moving: bool) -> String:
	if is_stunned:
		return "roll"
	if not is_moving:
		return "idle_down"

	var x := dir.x
	var y := dir.y

	# Use "move" animations when moving, "idle" when stationary
	var prefix := "move_" if is_moving else "idle_"

	# PURE CARDINAL DIRECTIONS
	if abs(x) < 0.4 and y < -0.4:
		return prefix + "up" if is_moving else "idle_down"  # No idle_up, fallback
	elif x < -0.4 and abs(y) < 0.4:
		return prefix + "left" if is_moving else "idle_down"  # No idle_left, fallback
	elif x > 0.4 and abs(y) < 0.4:
		return prefix + "right" if is_moving else "idle_down"  # No idle_right, fallback

	## DIAGONALS (any time both x and y have a decent magnitude)
	if abs(x) > 0.4 and abs(y) > 0.4:
		if y < 0.0:
			if is_moving:
				return "move_diag_left_up" if x < 0.0 else "move_diag_right_up"
			else:
				return "idle_down"  # No diagonal idles, fallback
		# DOWN
		else:
			if is_moving:
				return "move_diag_left_down" if x < 0.0 else "idle_down"
			else:
				return "idle_down"

	# Default fallback
	return "idle_down"


func _get_hit_anim_name(dir: Vector2) -> String:
	var x := dir.x
	var y := dir.y

	if dir == Vector2.ZERO:
		return "idle_down_hit"

	# PURE CARDINAL
	if abs(x) < 0.4 and y < -0.4:
		return "move_up_hit"
	elif x < -0.4 and abs(y) < 0.4:
		return "move_left_hit"
	elif x > 0.4 and abs(y) < 0.4:
		return "move_right_hit"

	# DIAGONALS
	if abs(x) > 0.4 and abs(y) > 0.4:
		if y < 0.0:
			return "move_diag_left_up_hit" if x < 0.0 else "move_diag_right_up_hit"
		else:
			return "move_diag_left_down_hit" if x < 0.0 else "idle_down_hit"

	return "idle_down_hit"


func _update_animation() -> void:
	if anim == null:
		return

	# === Death has highest priority ===
	if is_dead:
		if anim.animation != "die":
			anim.play("die")
		return

	# hit has top priority (unless rolling)
	if is_hit and not is_rolling:
		var hit_name := _get_hit_anim_name(last_move_dir)
		if anim.animation != hit_name:
			anim.play(hit_name)
		return

	if is_rolling:
		if anim.animation != "roll":
			anim.play("roll")
		return

	# Animation is now based on mouse direction, not movement
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = (mouse_pos - global_position).normalized()
	var is_moving := direction != Vector2.ZERO and not is_rolling

	var anim_name := _get_anim_name(mouse_dir, is_moving)

	if anim.animation != anim_name:
		anim.play(anim_name)
		
		
func _on_body_entered(body) -> void:
	print("ENTERE", body)

# Damage function (Initiates the death sequence)
func take_damage(amount: int) -> void:
	if is_dead: return # Prevent damage if already dead
	
	current_health -= amount
	emit_signal("health_changed", current_health)

	is_hit = true
	hit_timer = hit_duration
		
	if current_health <= 0.0 and not is_dead:
		current_health = 0.0
		is_dead = true

		# Stop all movement & actions
		is_hit = false
		is_rolling = false
		direction = Vector2.ZERO
		velocity = Vector2.ZERO

		# Stop trail effect if active
		if movement_trail:
			movement_trail.emitting = false

		# Play the death animation once
		if anim:
			anim.play("die")
		
# Scene change occurs only after the 'die' animation finishes, followed by a delay.
func _on_animation_finished(anim_name: StringName) -> void:
	if is_dead and anim_name == "die":
		var delay_time = 2.0
		
		# 1. Create a Timer (no need for await/async)
		var timer = get_tree().create_timer(delay_time)
		
		# 2. Connect the timer's 'timeout' signal to an anonymous function
		#    that executes the scene change.
		timer.timeout.connect(func():
			get_tree().change_scene_to_file("res://scene/main_menu.tscn")
		)
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

# Attack with current weapon using unified WeaponBase interface
func _shoot_current_weapon() -> void:
	var weapon: WeaponBase = _get_current_weapon()
	if weapon != null and weapon.has_method("attack"):
		weapon.attack()

# Get the current weapon instance
func _get_current_weapon() -> WeaponBase:
	match current_weapon:
		Weapon.SLIPPER:
			return slip_weapon as WeaponBase
		Weapon.RICE_MACHINE:
			return rice_weapon as WeaponBase
		Weapon.BROOM:
			return broom_weapon as WeaponBase
	return null

# Switch between weapons
func _switch_weapon() -> void:
	match current_weapon:
		Weapon.SLIPPER:
			current_weapon = Weapon.RICE_MACHINE
			print("Switched to Rice Machine Gun")
		Weapon.RICE_MACHINE:
			current_weapon = Weapon.BROOM
			print("Switched to Broom")
		Weapon.BROOM:
			current_weapon = Weapon.SLIPPER
			print("Switched to Slipper")

	_update_weapon_visibility()

# Update weapon visibility based on current weapon
func _update_weapon_visibility() -> void:
	if slip_weapon != null:
		slip_weapon.visible = (current_weapon == Weapon.SLIPPER)

	if rice_weapon != null:
		rice_weapon.visible = (current_weapon == Weapon.RICE_MACHINE)

	if broom_weapon != null:
		broom_weapon.visible = (current_weapon == Weapon.BROOM)

# Update weapon layering based on facing direction
func _update_weapon_layering() -> void:
	# Use mouse direction to determine if weapons should be in front or behind
	var mouse_pos = get_global_mouse_position()
	var mouse_dir = (mouse_pos - global_position).normalized()

	# If aiming up (negative Y), put weapons behind player
	# If aiming down (positive Y), put weapons in front
	var weapon_z = 1 if mouse_dir.y >= 0 else -1

	# Weapons stay at their fixed position - only update layering
	if slip_weapon != null:
		slip_weapon.z_index = weapon_z

	if rice_weapon != null:
		rice_weapon.z_index = weapon_z

	if broom_weapon != null:
		broom_weapon.z_index = weapon_z
		
		
func add_points(amount: int) -> void:
	current_points += amount
	emit_signal("points_changed", current_points)
	

func set_round(value: int) -> void:
	print("NEW ROUND", value)
	current_round = value
	emit_signal("round_changed", current_round)
