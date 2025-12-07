extends WeaponBase

@export var bullet_scene: PackedScene
@export var hide_duration: float = 0.2

@onready var weapon_pivot: Marker2D = $WeaponPivot
@onready var shooting_point: Marker2D = $WeaponPivot/Slipper/ShootingPoint
@onready var slipper_sprite: Node2D = $WeaponPivot/Slipper

func _ready():
	weapon_type = "Slipper"
	damage = 20.0
	cooldown = 0.3

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

	# Hide slipper sprite when thrown
	if slipper_sprite != null:
		slipper_sprite.visible = false
		get_tree().create_timer(hide_duration).timeout.connect(_show_slipper)

func _show_slipper() -> void:
	if slipper_sprite != null:
		slipper_sprite.visible = true
