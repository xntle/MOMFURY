#extends CharacterBody2D
#
#@onready var player = get_node("/root/Game/Player")
#@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
#
#@export var health: float = 200.0
#
#
#var throw_timer := 0.0
#var throw_speed := 250.0
#var normal_speed := 25.0
#var is_throwing := false
#var throw_duration := 0.2
#var throw_time_left := 0.0
#var push_timer: = 0.0
#
#const projectile_scene := preload("res://scene/Bosses/BossDaddy/BeerBottle.tscn") 
#
#func _ready():
	## First random cooldown 1 to 3 seconds
	#throw_timer = randf_range(1.0, 4.0)  
#
#func _physics_process(delta):
	#throw_timer -= delta
#
	#var direction = global_position.direction_to(player.global_position)
#
	## Start a throw when timer hits zero
	##if throw_timer <= 0.0:
		##is_throwing = true
		##throw_timer = randf_range(1.0, 10.0)  
		#
	## Dash or normal move
	#if is_throwing:
		##velocity = direction * throw_speed
		#shoot()
		#is_throwing = false
	#velocity = direction * normal_speed
#
	#move_and_slide()
	#if push_timer > 0.0:
		#push_timer = max(0,push_timer-delta)
		#player.move_and_collide(8 * player.move_speed * direction * delta)
	##rotation = direction.angle() +90
#
#func shoot() -> void:
	#if projectile_scene == null:
		#return
#
	#var projectile = projectile_scene.instantiate()
	#get_tree().current_scene.add_child(projectile)  # or get_parent(), depending on structure
#
	## Set initial position (e.g. player position or a gun muzzle position)
	#projectile.global_position = global_position
#
	## Choose direction: here, facing right or using input/aim direction
	#projectile.direction = (player.global_position - global_position).normalized()
	#
#
#
#func _on_area_2d_body_entered(body: Node2D) -> void:
	#if body == player:
		#player.take_damage(15)
		#player.apply_stun(0.2)
		#player.apply_intangibility(0.4)
		#push_timer = 0.2
#
## Damage function
#func take_damage(amount: float) -> void:
	#health -= amount
	#print("Boss Daddy took ", amount, " damage. Health: ", health)
#
	#if health <= 0:
		#print("Boss Daddy defeated!")
		#queue_free()
		
		
extends CharacterBody2D

@onready var player = get_node("/root/Game/Player")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D # Make sure this node exists!

@export var health: float = 200.0

# --- Boss State Variables ---
var throw_timer := 0.0
var throw_speed := 250.0 # Not used for movement in this version, but good to keep
var normal_speed := 25.0
var is_throwing := false
var throw_duration := 0.5   # Increased duration to SEE the attack animation
var throw_time_left := 0.0
var push_timer := 0.0

var is_hit := false
var hit_duration := 0.2
var hit_time_left := 0.0

const projectile_scene := preload("res://scene/Bosses/BossDaddy/BeerBottle.tscn") 

func _ready():
	# First random cooldown 1 to 4 seconds
	throw_timer = randf_range(1.0, 4.0) 
	
	# 🌟 NEW: Connect the signal for robust animation handling
	# This ensures one-shot animations (like attack/hit) finish before returning to walk.
	if anim:
		anim.animation_finished.connect(_on_animated_sprite_2d_animation_finished)
		anim.play("daddy_walk_right") # Start with an idle or walk animation

func _physics_process(delta):
	throw_timer -= delta

	var direction = global_position.direction_to(player.global_position)
	
	# --- 1. Update Timers ---
	if is_hit:
		hit_time_left -= delta
		if hit_time_left <= 0.0:
			is_hit = false

	if is_throwing:
		throw_time_left -= delta
		if throw_time_left <= 0.0:
			is_throwing = false
			# The signal handler will transition back to walk/idle


	# --- 2. Start Throwing State ---
	if not is_throwing and not is_hit and throw_timer <= 0.0:
		is_throwing = true
		throw_time_left = throw_duration
		throw_timer = randf_range(1.0, 4.0) # Next throw delay

		if anim:
			print("Playing attack anim: daddy_attack")
			anim.play("daddy_attack") # Play the attack animation
			shoot() # Throw projectile at start of animation
		
	# --- 3. Movement ---
	if is_throwing or is_hit:
		# Stand still while attacking or getting hit
		velocity = Vector2.ZERO
	else:
		velocity = direction * normal_speed

	move_and_slide()
	
	# Push player back logic (left unchanged)
	if push_timer > 0.0:
		push_timer = max(0, push_timer - delta)
		player.move_and_collide(8 * player.move_speed * direction * delta)
	
	# --- 4. Animation (Walk/Idle/Facing) ---
	# Only update walk/idle if not busy with a one-shot attack or hit animation
	if not is_throwing and not is_hit and anim:
		# Flip sprite to face player horizontally
		if abs(direction.x) > 0.1:
			anim.flip_h = direction.x < 0
			
		if velocity.length() > 1.0:
			# Check if we are moving and not already walking
			if anim.animation != "daddy_walk_right": # Change "daddy_walk_right" to a simpler "daddy_walk"
				anim.play("daddy_walk_right")


func shoot() -> void:
	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile) 

	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	
	
# 🌟 NEW: Signal handler to transition animations after one-shot actions finish
func _on_animated_sprite_2d_animation_finished(anim_name: StringName) -> void:
	# If the boss finishes the attack or hit animation, transition back to walk/idle
	if anim_name == "daddy_attack" or anim_name == "daddy_hit":
		if velocity.length() > 1.0:
			anim.play("daddy_walk_right")



func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == player:
		player.take_damage(15)
		player.apply_stun(0.2)
		player.apply_intangibility(0.4)
		push_timer = 0.2

# Damage function
func take_damage(amount: float) -> void:
	health -= amount
	print("Boss Daddy took ", amount, " damage. Health: ", health)
	
	# 🌟 NEW: Play hit animation
	if anim:
		anim.play("daddy_hit") # Play hit animation
	is_hit = true
	hit_time_left = hit_duration

	if health <= 0:
		print("Boss Daddy defeated!")
		queue_free()
