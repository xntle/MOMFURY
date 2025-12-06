extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate: float = 0.02

var can_shoot: bool = true
var shoot_timer: float = 0.0
@onready var shooting_point = $WeaponPivot/Gun/ShootingPoint


func _process(delta):
	if shoot_timer > 0:
		shoot_timer -= delta
		if shoot_timer <= 0:
			can_shoot = true

	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)


func shoot() -> bool:
	if not can_shoot or bullet_scene == null:
		return false

	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	
	bullet.global_position = shooting_point
	
	bullet.direction = Vector2.RIGHT.rotated(rotation)
	
	can_shoot = false
	shoot_timer = fire_rate
	
	return true
