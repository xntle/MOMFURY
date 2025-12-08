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
	else:
		print("ERROR: no shooting point")


	# Direction based on weapon rotation
	var mouse_pos = get_global_mouse_position()
	bullet.direction = (mouse_pos - player.global_position).normalized()
