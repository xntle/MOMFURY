extends Area2D

@export var bullet_scene: PackedScene

func _process(delta):
	var mouse_pos = get_global_mouse_position()
	$WeaponPivot.look_at(mouse_pos)
	
func shoot():
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position

	bullet.direction = transform.x.normalized()

	get_parent().add_child(bullet)
