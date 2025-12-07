extends WeaponBase

@export var bullet_scene: PackedScene
@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var shooting_point: Marker2D = $WeaponPivot/Slipper/ShootingPoint

func _ready():
	weapon_type = "Slipper"
	damage = 20.0
	cooldown = 0.3

func _process(delta):
	# Call parent to handle cooldown and rotation
	super._process(delta)

	# Rotate the weapon pivot to face mouse
	if weapon_pivot != null:
		var mouse_pos = get_global_mouse_position()
		weapon_pivot.look_at(mouse_pos)

# Override attack method from WeaponBase
func attack() -> bool:
	if not super.attack():
		return false

	_shoot_bullet()
	return true

func _shoot_bullet() -> void:
	if bullet_scene == null:
		print("ERROR: bullet_scene is null for Slipper!")
		return

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)

	# Use shooting point if available, otherwise use weapon position
	if shooting_point != null:
		bullet.global_position = shooting_point.global_position
	else:
		bullet.global_position = global_position

	# Direction is based on the weapon pivot rotation
	var mouse_pos = get_global_mouse_position()
	bullet.direction = (mouse_pos - bullet.global_position).normalized()
