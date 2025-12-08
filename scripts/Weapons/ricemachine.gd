extends WeaponBase

@export var bullet_scene: PackedScene
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var shooting_point: Marker2D = $WeaponPivot/Gun/ShootingPoint
@onready var player = get_tree().current_scene.get_node("Player")
@onready var rice_gun_sound =  load("res://assets/sound/Mom/RicechineGun.wav") as AudioStream

func _ready():
	weapon_type = "Rice Machine"
	damage = 10.0
	cooldown = 0.1  # Fast fire rate


func _process(delta):
	# Call parent to handle cooldown
	super._process(delta)

	# Rotate the weapon pivot to face mouse - simple pivot
	if weapon_pivot != null:
		var mouse_pos = get_global_mouse_position()
		var angle_to_mouse = global_position.angle_to_point(mouse_pos)
		weapon_pivot.rotation = angle_to_mouse

# Override attack method from WeaponBase
func attack() -> bool:
	if not super.attack():
		return false

	_shoot_bullet()
	return true

func _shoot_bullet() -> void:
	if bullet_scene == null:
		print("ERROR: bullet_scene is null for Rice Machine!")
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# Use shooting point if available
	if shooting_point != null:
		bullet.global_position = shooting_point.global_position
		# Create muzzle flash at shooting point
		_create_muzzle_flash()
	else:
		print("ERROR: no shooting point")


	# Direction based on weapon rotation
	var mouse_pos = get_global_mouse_position()
	bullet.direction = (mouse_pos - player.global_position).normalized()


func _create_muzzle_flash() -> void:
	# Create particle effect for muzzle flash
	var particles = CPUParticles2D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = shooting_point.global_position

	# Fire-like appearance
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 8
	particles.lifetime = 0.15
	particles.speed_scale = 2.0

	# Direction and spread
	particles.direction = Vector2(cos(weapon_pivot.rotation), sin(weapon_pivot.rotation))
	particles.spread = 25.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 120.0

	# Particle shape and size
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0

	# Colors - orange/yellow fire gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.8, 0.2, 1.0))  # Bright yellow
	gradient.add_point(0.5, Color(1.0, 0.4, 0.1, 0.8))  # Orange
	gradient.add_point(1.0, Color(0.3, 0.1, 0.0, 0.0))  # Dark red, transparent
	particles.color_ramp = gradient

	# Gravity and damping for realistic effect
	particles.gravity = Vector2(0, -50)
	particles.damping_min = 50.0
	particles.damping_max = 100.0

	# Auto-cleanup after particles finish
	get_tree().create_timer(0.3).timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)
