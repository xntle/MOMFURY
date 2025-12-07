class_name WeaponBase
extends Node2D

# Common weapon properties
@export var damage: float = 10.0
@export var cooldown: float = 0.5
@export var weapon_type: String = "Base"

# Cooldown tracking
var can_attack: bool = true
var attack_timer: float = 0.0


func _ready():
	# Override in subclass if needed
	pass


func _process(delta):
	# Update cooldown timer
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
			_on_cooldown_finished()


# Virtual method - override in subclasses
func attack() -> bool:
	if not can_attack:
		return false
	
	can_attack = false
	attack_timer = cooldown
	return true


# Called when cooldown finishes - override if needed
func _on_cooldown_finished():
	pass


# Get the owner PlayerController if needed
func get_player() -> PlayerController:
	return get_parent() as PlayerController
