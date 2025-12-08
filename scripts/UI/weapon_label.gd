extends Label

@export var player: PlayerController

var display_timer: float = 0.0
var display_duration: float = 2.0
var fade_duration: float = 0.5

var last_weapon = null

func _ready() -> void:
	modulate.a = 0.0  # Start invisible

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return

	# Check if weapon changed
	var current_weapon = player.current_weapon
	if current_weapon != last_weapon:
		last_weapon = current_weapon
		_show_weapon_name()
		display_timer = display_duration

	# Handle fade out
	if display_timer > 0.0:
		display_timer -= delta

		if display_timer <= fade_duration:
			# Fade out
			modulate.a = display_timer / fade_duration
		else:
			# Fully visible
			modulate.a = 1.0
	else:
		modulate.a = 0.0

func _show_weapon_name() -> void:
	# Update text based on weapon enum
	match player.current_weapon:
		PlayerController.Weapon.SLIPPER:
			text = "SLIPPER"
		PlayerController.Weapon.RICE_MACHINE:
			text = "RICE MACHINE GUN"
		PlayerController.Weapon.BROOM:
			text = "BROOM"
