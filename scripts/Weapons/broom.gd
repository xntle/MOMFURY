extends WeaponBase

@export var attack_duration: float = 0.2
@export var hit_effect_scene: PackedScene

var is_attacking: bool = false

@onready var hitbox: Area2D = $Hitbox
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready():
	weapon_type = "Broom"
	damage = 25.0
	cooldown = 0.5

	if hitbox != null:
		hitbox.monitoring = false
		hitbox.body_entered.connect(_on_hitbox_body_entered)


func _process(delta):
	# Call parent to handle cooldown and rotation
	super._process(delta)


# Override attack method from WeaponBase
func attack() -> bool:
	if not super.attack():
		return false

	is_attacking = true
	
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

		# Spawn hit effect
		if hit_effect_scene != null:
			var hit_effect = hit_effect_scene.instantiate()
			get_tree().current_scene.add_child(hit_effect)
			hit_effect.global_position = body.global_position
