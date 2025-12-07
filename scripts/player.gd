#extends CharacterBody2D
#class_name PlayerController
#
#@export var move_speed: float = 30.0
#@export var roll_speed: float = 300.0
#@export var roll_time: float = 0.15
#@export var roll_cooldown: float = 0.4
#@export var max_health: float = 100.0
#
## Weapon system
#enum Weapon { SLIPPER, RICE_MACHINE, BROOM }
#var current_weapon: Weapon = Weapon.SLIPPER
#
#var current_health: float = max_health
#var direction: Vector2
#var is_rolling:bool = false
#var roll_timer:float = 0.0
#var cooldown_timer:float = 0.0
#var roll_dir: Vector2
#var is_stunned:bool = false
#var stun_timer:float = 0.0
#var intangibility_timer:float = 0.0
#
#signal health_changed(new_health:int)
#
#
#
#var last_move_dir: Vector2 = Vector2.DOWN 
#@onready var anim: AnimationPlayer = $AnimationPlayer
#@onready var shoot_point: Marker2D = $ShootingPoint
#@onready var slip_weapon: Node2D = $slip
#@onready var rice_weapon: Node2D = $Ricechine
#@onready var broom_weapon: Node2D = $Broom
#@onready var movement_trail: CPUParticles2D = $MovementTrail
#
## Slow effect tracking
#var is_slowed: bool = false
#var slow_multiplier: float = 1.0
#
#func _ready():
	##$AnimationPlayer.play("idle_down")
	#anim.play("idle_down")
#
	## Initialize weapon visibility
	#_update_weapon_visibility()
#
#
#func _physics_process(delta):
	## cooldown
	#if cooldown_timer > 0:
		#cooldown_timer -= delta
#
	## dodge rolling condition
	#if is_rolling:
		#roll_timer -= delta
#
		#move_and_collide(roll_dir * roll_speed * delta)
#
		## Emit intense trail during roll
		#if movement_trail != null:
			#movement_trail.emitting = true
			#movement_trail.amount = 15
			#movement_trail.scale_amount_max = 6.0
#
		#if roll_timer <= 0:
			#is_rolling = false
			#cooldown_timer = roll_cooldown
			#collision_layer = 1
			#return
#
		#return  
	## movement input
	#if Input.is_action_pressed("move_down"):
		#direction.y = 1
	#elif Input.is_action_pressed("move_up"):
		#direction.y = -1
	#else:
		#direction.y = 0
#
	#if Input.is_action_pressed("move_right"):
		#direction.x = 1
	#elif Input.is_action_pressed("move_left"):
		#direction.x = -1
	#else:
		#direction.x = 0
		#
	## normalize diagonal speed
	#if direction != Vector2.ZERO:
		#direction = direction.normalized()
		#last_move_dir = direction
		#_update_weapon_layering()
#
	#if current_health >= max_health:
		#current_health = max_health
	#if current_health <= 0.0:
		#current_health = 0.0
		##Add death logic here
		#get_tree().change_scene_to_file("res://scene/main_menu.tscn")
#
	## weapon switching
	#if Input.is_action_just_pressed("switch"):
		#_switch_weapon()
#
	## shooting with current weapon (weapons handle their own cooldowns)
	#if Input.is_action_pressed("shoot") and not is_rolling and not is_stunned:
		#_shoot_current_weapon()
#
	## dodge rolling
	#if Input.is_action_just_pressed("roll") and cooldown_timer <= 0.0 and (not is_stunned):
		#var roll_input_dir := direction
#
		## If no current input, roll in the last move direction (facing)
		#if roll_input_dir == Vector2.ZERO:
			#roll_input_dir = last_move_dir
#
	## Safety: if last_move_dir was ever zero (just in case), don't start roll
		#if roll_input_dir == Vector2.ZERO:
			#return
#
		#is_rolling = true
		#roll_timer = roll_time
		#roll_dir = roll_input_dir.normalized()
		#collision_layer = 8
		#anim.play("roll")
		#return
#
	## normal movement
	#velocity = move_speed * slow_multiplier * direction * delta * 200
#
	#if not is_stunned:
		#move_and_slide()
#
	## Update movement trail
	#if movement_trail != null:
		#if direction != Vector2.ZERO and not is_stunned:
			## Light trail during normal movement
			#movement_trail.emitting = true
			#movement_trail.amount = 8
			#movement_trail.scale_amount_max = 4.0
		#else:
			## Stop trail when idle
			#movement_trail.emitting = false
#
	## stun duration logic
	#stun_timer = max(0,stun_timer-delta)
	#if stun_timer <= 0:
		#is_stunned = false
	#
	## intangibility duration logic
	#intangibility_timer = max(0,intangibility_timer-delta)
	#if intangibility_timer <= 0:
		#if not is_rolling:
			#collision_layer = 1
	#_update_animation()
#
### Animation
#func _get_anim_name(dir: Vector2, is_moving: bool) -> String:
	#if is_stunned:
		#return "roll"
	#if not is_moving:
		#return "idle_down"  # your only idle anim for now
#
	#var x := dir.x
	#var y := dir.y
#
	## PURE CARDINAL DIRECTIONS
	#if abs(x) < 0.4 and y < -0.4:
		#return "move_up"
	#elif x < -0.4 and abs(y) < 0.4:
		#return "move_left"
	#elif x > 0.4 and abs(y) < 0.4:
		#return "move_right"
#
	### DIAGONALS (any time both x and y have a decent magnitude)
	##if x < 0.0:
		##return "move_diag_left_up"
	##elif x > 0.0:
		##return "move_diag_right_up"
	#if abs(x) > 0.4 and abs(y) > 0.4:
		## UP
		#if y < 0.0:
			#return "move_diag_left_up" if x < 0.0 else "move_diag_right_up"
		## DOWN
		#else:
			#return "move_diag_left_down" if x < 0.0 else "idle_down"
#
	 #
#
	## moving straight down but you don't have move_down yet → reuse idle_down
	#return "idle_down"
#
#
#func _update_animation() -> void:
	#if is_rolling:
		#if anim.current_animation != "roll":
			#anim.play("roll")
		#return
		#
	#var is_moving := direction != Vector2.ZERO and not is_rolling
	#var dir_vec := last_move_dir
#
	#var anim_name := _get_anim_name(dir_vec, is_moving)
#
	#if anim.current_animation != anim_name:
		#anim.play(anim_name)
		#
		#
#func _on_body_entered(body) -> void:
	#print("ENTERE", body)
##Damage function
#func take_damage(amount: int) -> void:
	#current_health -= amount
	#emit_signal("health_changed", current_health)
#
## Slow effect functions
#func apply_slow(multiplier: float) -> void:
	#is_slowed = true
	#slow_multiplier = multiplier
#
#func remove_slow() -> void:
	#is_slowed = false
	#slow_multiplier = 1.0
	#
#func apply_stun(duration) -> void:
	#stun_timer = duration
	#is_stunned = true
#
#func apply_intangibility(duration) -> void:
	#intangibility_timer = duration
	#collision_layer = 8
#
## Attack with current weapon using unified WeaponBase interface
#func _shoot_current_weapon() -> void:
	#var weapon: WeaponBase = _get_current_weapon()
	#if weapon != null and weapon.has_method("attack"):
		#weapon.attack()
#
## Get the current weapon instance
#func _get_current_weapon() -> WeaponBase:
	#match current_weapon:
		#Weapon.SLIPPER:
			#return slip_weapon as WeaponBase
		#Weapon.RICE_MACHINE:
			#return rice_weapon as WeaponBase
		#Weapon.BROOM:
			#return broom_weapon as WeaponBase
	#return null
#
## Switch between weapons
#func _switch_weapon() -> void:
	#match current_weapon:
		#Weapon.SLIPPER:
			#current_weapon = Weapon.RICE_MACHINE
			#print("Switched to Rice Machine Gun")
		#Weapon.RICE_MACHINE:
			#current_weapon = Weapon.BROOM
			#print("Switched to Broom")
		#Weapon.BROOM:
			#current_weapon = Weapon.SLIPPER
			#print("Switched to Slipper")
#
	#_update_weapon_visibility()
#
## Update weapon visibility based on current weapon
#func _update_weapon_visibility() -> void:
	#if slip_weapon != null:
		#slip_weapon.visible = (current_weapon == Weapon.SLIPPER)
#
	#if rice_weapon != null:
		#rice_weapon.visible = (current_weapon == Weapon.RICE_MACHINE)
#
	#if broom_weapon != null:
		#broom_weapon.visible = (current_weapon == Weapon.BROOM)
#
## Update weapon layering based on facing direction
#func _update_weapon_layering() -> void:
	## If facing up (negative Y), put weapons behind player
	## If facing down/forward (positive Y), put weapons in front
	#var weapon_z = 1 if last_move_dir.y >= 0 else -1
#
	## Calculate weapon position based on direction
	#var weapon_offset = last_move_dir.normalized() * 6.0
	## Add slight offset perpendicular to direction for better positioning
	#var perpendicular = Vector2(-last_move_dir.y, last_move_dir.x) * 4.0
	#var weapon_pos = weapon_offset + perpendicular
#
	#if slip_weapon != null:
		#slip_weapon.z_index = weapon_z
		#slip_weapon.position = weapon_pos
#
	#if rice_weapon != null:
		#rice_weapon.z_index = weapon_z
		#rice_weapon.position = weapon_pos
#
	#if broom_weapon != null:
		#broom_weapon.z_index = weapon_z
		#broom_weapon.position = weapon_pos
#
#
#extends CharacterBody2D
#class_name PlayerController
#
#@export var move_speed: float = 30.0
#@export var roll_speed: float = 300.0
#@export var roll_time: float = 0.15
#@export var roll_cooldown: float = 0.4
#@export var max_health: float = 100.0
#
## Weapon system
#enum Weapon { SLIPPER, RICE_MACHINE, BROOM }
#var current_weapon: Weapon = Weapon.SLIPPER
#
#var current_health: float = max_health
#var direction: Vector2
#var is_rolling: bool = false
#var roll_timer: float = 0.0
#var cooldown_timer: float = 0.0
#var roll_dir: Vector2
#var is_stunned: bool = false
#var stun_timer: float = 0.0
#var intangibility_timer: float = 0.0
#
#signal health_changed(new_health:int)
#
#var last_move_dir: Vector2 = Vector2.DOWN 
#
## ✅ use the AnimatedSprite2D node named "animation"
#@onready var anim: AnimatedSprite2D = $animation
#
#@onready var shoot_point: Marker2D = $ShootingPoint
#@onready var slip_weapon: Node2D = $slip
#@onready var rice_weapon: Node2D = $Ricechine
#@onready var broom_weapon: Node2D = $Broom
#@onready var movement_trail: CPUParticles2D = $MovementTrail
#
## Slow effect tracking
#var is_slowed: bool = false
#var slow_multiplier: float = 1.0
#
#func _ready():
	#if anim:
		#anim.play("idle_down")
	#_update_weapon_visibility()
#
#
#func _physics_process(delta):
	## cooldown
	#if cooldown_timer > 0.0:
		#cooldown_timer -= delta
#
	## dodge rolling condition
	#if is_rolling:
		#roll_timer -= delta
		#move_and_collide(roll_dir * roll_speed * delta)
#
		## Emit intense trail during roll
		#if movement_trail != null:
			#movement_trail.emitting = true
			#movement_trail.amount = 15
			#movement_trail.scale_amount_max = 6.0
#
		#if roll_timer <= 0.0:
			#is_rolling = false
			#cooldown_timer = roll_cooldown
			#collision_layer = 1
		#return  
#
	## movement input
	#if Input.is_action_pressed("move_down"):
		#direction.y = 1
	#elif Input.is_action_pressed("move_up"):
		#direction.y = -1
	#else:
		#direction.y = 0
#
	#if Input.is_action_pressed("move_right"):
		#direction.x = 1
	#elif Input.is_action_pressed("move_left"):
		#direction.x = -1
	#else:
		#direction.x = 0
		#
	## normalize diagonal speed
	#if direction != Vector2.ZERO:
		#direction = direction.normalized()
		#last_move_dir = direction
		#_update_weapon_layering()
#
	## health clamp + death
	#if current_health >= max_health:
		#current_health = max_health
	#if current_health <= 0.0:
		#current_health = 0.0
		#get_tree().change_scene_to_file("res://scene/main_menu.tscn")
#
	## weapon switching
	#if Input.is_action_just_pressed("switch"):
		#_switch_weapon()
#
	## shooting with current weapon
	#if Input.is_action_pressed("shoot") and not is_rolling and not is_stunned:
		#_shoot_current_weapon()
#
	## dodge rolling
	#if Input.is_action_just_pressed("roll") and cooldown_timer <= 0.0 and (not is_stunned):
		#var roll_input_dir := direction
#
		## If no current input, roll in the last move direction (facing)
		#if roll_input_dir == Vector2.ZERO:
			#roll_input_dir = last_move_dir
#
		#if roll_input_dir == Vector2.ZERO:
			#return
#
		#is_rolling = true
		#roll_timer = roll_time
		#roll_dir = roll_input_dir.normalized()
		#collision_layer = 8
		#if anim:
			#anim.play("roll")
		#return
#
	## normal movement
	#velocity = move_speed * slow_multiplier * direction * delta * 200.0
#
	#if not is_stunned:
		#move_and_slide()
#
	## Update movement trail
	#if movement_trail != null:
		#if direction != Vector2.ZERO and not is_stunned:
			#movement_trail.emitting = true
			#movement_trail.amount = 8
			#movement_trail.scale_amount_max = 4.0
		#else:
			#movement_trail.emitting = false
#
	## stun duration logic
	#stun_timer = max(0.0, stun_timer - delta)
	#if stun_timer <= 0.0:
		#is_stunned = false
	#
	## intangibility duration logic
	#intangibility_timer = max(0.0, intangibility_timer - delta)
	#if intangibility_timer <= 0.0:
		#if not is_rolling:
			#collision_layer = 1
#
	#_update_animation()
#
### Animation
#func _get_anim_name(dir: Vector2, is_moving: bool) -> String:
	#if is_stunned:
		#return "roll"
	#if not is_moving:
		#return "idle_down"
#
	#var x := dir.x
	#var y := dir.y
#
	## PURE CARDINAL DIRECTIONS
	#if abs(x) < 0.4 and y < -0.4:
		#return "move_up"
	#elif x < -0.4 and abs(y) < 0.4:
		#return "move_left"
	#elif x > 0.4 and abs(y) < 0.4:
		#return "move_right"
#
	## DIAGONALS
	#if abs(x) > 0.4 and abs(y) > 0.4:
		## UP
		#if y < 0.0:
			#return "move_diag_left_up" if x < 0.0 else "move_diag_right_up"
		## DOWN
		#else:
			#return "move_diag_left_down" if x < 0.0 else "idle_down"
#
	## moving straight down but you don't have move_down yet → reuse idle_down
	#return "idle_down"
#
#
#func _update_animation() -> void:
	#if anim == null:
		#return
#
	#if is_rolling:
		#if anim.animation != "roll":
			#anim.play("roll")
		#return
		#
	#var is_moving := direction != Vector2.ZERO and not is_rolling
	#var dir_vec := last_move_dir
#
	#var anim_name := _get_anim_name(dir_vec, is_moving)
#
	#if anim.animation != anim_name:
		#anim.play(anim_name)
		#
		#
#func _on_body_entered(body) -> void:
	#print("ENTERE", body)
#
## Damage function
#func take_damage(amount: int) -> void:
	#current_health -= amount
	#emit_signal("health_changed", current_health)
#
## Slow effect functions
#func apply_slow(multiplier: float) -> void:
	#is_slowed = true
	#slow_multiplier = multiplier
#
#func remove_slow() -> void:
	#is_slowed = false
	#slow_multiplier = 1.0
	#
#func apply_stun(duration) -> void:
	#stun_timer = duration
	#is_stunned = true
#
#func apply_intangibility(duration) -> void:
	#intangibility_timer = duration
	#collision_layer = 8
#
## Attack with current weapon using unified WeaponBase interface
#func _shoot_current_weapon() -> void:
	#var weapon: WeaponBase = _get_current_weapon()
	#if weapon != null and weapon.has_method("attack"):
		#weapon.attack()
#
## Get the current weapon instance
#func _get_current_weapon() -> WeaponBase:
	#match current_weapon:
		#Weapon.SLIPPER:
			#return slip_weapon as WeaponBase
		#Weapon.RICE_MACHINE:
			#return rice_weapon as WeaponBase
		#Weapon.BROOM:
			#return broom_weapon as WeaponBase
	#return null
#
## Switch between weapons
#func _switch_weapon() -> void:
	#match current_weapon:
		#Weapon.SLIPPER:
			#current_weapon = Weapon.RICE_MACHINE
			#print("Switched to Rice Machine Gun")
		#Weapon.RICE_MACHINE:
			#current_weapon = Weapon.BROOM
			#print("Switched to Broom")
		#Weapon.BROOM:
			#current_weapon = Weapon.SLIPPER
			#print("Switched to Slipper")
#
	#_update_weapon_visibility()
#
## Update weapon visibility based on current weapon
#func _update_weapon_visibility() -> void:
	#if slip_weapon != null:
		#slip_weapon.visible = (current_weapon == Weapon.SLIPPER)
#
	#if rice_weapon != null:
		#rice_weapon.visible = (current_weapon == Weapon.RICE_MACHINE)
#
	#if broom_weapon != null:
		#broom_weapon.visible = (current_weapon == Weapon.BROOM)
#
## Update weapon layering based on facing direction
#func _update_weapon_layering() -> void:
	#var weapon_z = 1 if last_move_dir.y >= 0.0 else -1
#
	#var weapon_offset = last_move_dir.normalized() * 6.0
	#var perpendicular = Vector2(-last_move_dir.y, last_move_dir.x) * 4.0
	#var weapon_pos = weapon_offset + perpendicular
#
	#if slip_weapon != null:
		#slip_weapon.z_index = weapon_z
		#slip_weapon.position = weapon_pos
#
	#if rice_weapon != null:
		#rice_weapon.z_index = weapon_z
		#rice_weapon.position = weapon_pos
#
	#if broom_weapon != null:
		#broom_weapon.z_index = weapon_z
		#broom_weapon.position = weapon_pos


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

signal health_changed(new_health:int)

var last_move_dir: Vector2 = Vector2.DOWN 

@onready var anim: AnimatedSprite2D = $animation

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


func _physics_process(delta):
	# cooldown
	if cooldown_timer > 0.0:
		cooldown_timer -= delta

	# update hit timer
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0.0:
			is_hit = false

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
		_update_weapon_layering()

	# health clamp + death
	if current_health >= max_health:
		current_health = max_health
	if current_health <= 0.0:
		current_health = 0.0
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")

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

	# PURE CARDINAL DIRECTIONS
	if abs(x) < 0.4 and y < -0.4:
		return "move_up"
	elif x < -0.4 and abs(y) < 0.4:
		return "move_left"
	elif x > 0.4 and abs(y) < 0.4:
		return "move_right"

	# DIAGONALS
	if abs(x) > 0.4 and abs(y) > 0.4:
		if y < 0.0:
			return "move_diag_left_up" if x < 0.0 else "move_diag_right_up"
		else:
			return "move_diag_left_down" if x < 0.0 else "idle_down"

	# moving straight down but you don't have move_down yet → reuse idle_down
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
		
	var is_moving := direction != Vector2.ZERO and not is_rolling
	var dir_vec := last_move_dir
	var anim_name := _get_anim_name(dir_vec, is_moving)

	if anim.animation != anim_name:
		anim.play(anim_name)
		
		
func _on_body_entered(body) -> void:
	print("ENTERE", body)

# Damage function
func take_damage(amount: int) -> void:
	current_health -= amount
	emit_signal("health_changed", current_health)

	is_hit = true
	hit_timer = hit_duration

	if current_health <= 0.0:
		current_health = 0.0
		get_tree().change_scene_to_file("res://scene/main_menu.tscn")

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
	var weapon_z = 1 if last_move_dir.y >= 0.0 else -1

	var weapon_offset = last_move_dir.normalized() * 6.0
	var perpendicular = Vector2(-last_move_dir.y, last_move_dir.x) * 4.0
	var weapon_pos = weapon_offset + perpendicular

	if slip_weapon != null:
		slip_weapon.z_index = weapon_z
		slip_weapon.position = weapon_pos

	if rice_weapon != null:
		rice_weapon.z_index = weapon_z
		rice_weapon.position = weapon_pos

	if broom_weapon != null:
		broom_weapon.z_index = weapon_z
		broom_weapon.position = weapon_pos
