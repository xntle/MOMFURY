extends WeaponBase

@export var attack_duration: float = 0.2
@export var hit_effect_scene: PackedScene
@export var knockback_force: float = 300.0

var is_attacking: bool = false

@onready var hitbox: Area2D = $Hitbox
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var shoot_sound: AudioStreamPlayer2D = $ShootSound

var broom_sound: AudioStream


func _ready():
	weapon_type = "Broom"
	damage = 80.0
	cooldown = 0.5

	# Load broom swing sound
	broom_sound = load("res://assets/sound/Mom/Broom.wav") as AudioStream

	if hitbox != null:
		hitbox.monitoring = false
		hitbox.body_entered.connect(_on_hitbox_body_entered)


func _process(delta):
	# Call parent to handle cooldown
	super._process(delta)

	# Rotate to face mouse - simple pivot
	var mouse_pos = get_global_mouse_position()
	var angle_to_mouse = global_position.angle_to_point(mouse_pos)
	rotation = angle_to_mouse


# Override attack method from WeaponBase
func attack() -> bool:
	if not super.attack():
		return false

	is_attacking = true

	# Play broom swing sound
	if shoot_sound != null and broom_sound != null:
		shoot_sound.stream = broom_sound
		shoot_sound.play()

	# Play swing animation ONLY when we attack
	if anim:
		anim.stop()          # restart from frame 0
		anim.play("broom_swing")


	# Enable hitbox for attack duration
	if hitbox != null:
		hitbox.monitoring = true
		# Disable after attack duration
		get_tree().create_timer(attack_duration).timeout.connect(_disable_hitbox)

	print("Broom swing!")
	return true


func _on_cooldown_finished():
	is_attacking = false
	if hitbox != null:
		hitbox.monitoring = false


func _disable_hitbox():
	if hitbox != null:
		hitbox.monitoring = false


func _on_hitbox_body_entered(body):
	if body is PlayerController:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Broom hit: ", body.name, " for ", damage, " damage")

		# Apply knockback
		_apply_knockback(body)

		# Spawn hit effect at hitbox center
		if hit_effect_scene != null:
			var hit_effect = hit_effect_scene.instantiate()
			get_tree().current_scene.add_child(hit_effect)
			# Spawn at hitbox position (where the broom actually hit)
			var hitbox_global_pos = hitbox.global_position
			hit_effect.global_position = hitbox_global_pos
			print("Spawned hit effect at: ", hitbox_global_pos)


func _apply_knockback(body: Node2D) -> void:
	# Calculate direction from player to enemy
	var player = get_player()
	if player == null:
		return

	var knockback_dir = (body.global_position - player.global_position).normalized()

	# Apply knockback based on enemy type
	if body is CharacterBody2D:
		# For CharacterBody2D enemies, set their velocity
		body.velocity = knockback_dir * knockback_force
	elif body.has_method("apply_knockback"):
		# If enemy has custom knockback method
		body.apply_knockback(knockback_dir * knockback_force)
	elif body is RigidBody2D:
		# For RigidBody2D
		body.apply_central_impulse(knockback_dir * knockback_force)
