extends Area2D

@export var projectile_scene: PackedScene    
@export var shoot_cooldown := 0.2

var shoot_timer := 0.0

func _physics_process(delta):
	shoot_timer -= delta

	# Always rotate toward mouse
	look_at(get_global_mouse_position())

	# Shoot on click
	if Input.is_action_pressed("shoot") and shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_cooldown
		
func shoot():
	if projectile_scene == null:
		print("No projectile assigned!")
		return

	var p = projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)

	p.global_position = global_position
	p.rotation = rotation

	# IMPORTANT: projectile script MUST have `velocity` variable
	if p.has_method("_set_velocity"):
		p._set_velocity(Vector2.RIGHT.rotated(rotation))
	elif "velocity" in p:
		p.velocity = Vector2.RIGHT.rotated(rotation) * 400
