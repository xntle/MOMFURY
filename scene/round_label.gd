extends Label
@export var player: CharacterBody2D

func _ready() -> void:
	if player:
		player.connect("round_changed", update_round)
		update_round(player.current_round)

func update_round(new_round: int) -> void:
	text = "Round: %d" % new_round
